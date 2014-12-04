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
#ifndef TIGHTDB_UTIL_TYPE_TRAITS_HPP
#define TIGHTDB_UTIL_TYPE_TRAITS_HPP

#include <stdint.h>
#include <climits>
#include <cwchar>
#include <limits>

#ifdef TIGHTDB_HAVE_CXX11_TYPE_TRAITS
#  include <type_traits>
#endif

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>
#include <tightdb/util/meta.hpp>
#include <tightdb/util/type_list.hpp>

namespace tightdb {
namespace util {


template<class T> struct IsConst          { static const bool value = false; };
template<class T> struct IsConst<const T> { static const bool value = true;  };

template<class T> struct IsVolatile             { static const bool value = false; };
template<class T> struct IsVolatile<volatile T> { static const bool value = true;  };

template<class T> struct RemoveConst          { typedef T type; };
template<class T> struct RemoveConst<const T> { typedef T type; };

template<class T> struct RemoveVolatile             { typedef T type; };
template<class T> struct RemoveVolatile<volatile T> { typedef T type; };

template<class T> struct RemoveCV {
    typedef typename RemoveVolatile<typename RemoveConst<T>::type>::type type;
};

template<class From, class To> struct CopyConst {
private:
    typedef typename RemoveConst<To>::type type_1;
public:
    typedef typename CondType<IsConst<From>::value, const type_1, type_1>::type type;
};

template<class T> struct RemovePointer                    { typedef T type; };
template<class T> struct RemovePointer<T*>                { typedef T type; };
template<class T> struct RemovePointer<T* const>          { typedef T type; };
template<class T> struct RemovePointer<T* volatile>       { typedef T type; };
template<class T> struct RemovePointer<T* const volatile> { typedef T type; };


/// Member `value` is true if, and only if the specified type is an
/// integral type. Same as `std::is_integral` in C++11, however,
/// implementation-defined extended integer types are recognized only
/// when TIGHTDB_HAVE_CXX11_TYPE_TRAITS is defined.
template<class T> struct IsIntegral;


/// Member `value` is true if, and only if the specified type is a
/// floating point type. Same as `std::is_floating_point` in C++11.
template<class T> struct IsFloatingPoint;


/// Member `type` is the type resulting from integral or
/// floating-point promotion of a value of type `T`.
///
/// \note Enum types are supported only when the compiler supports the
/// C++11 'decltype' feature.
template<class T> struct Promote;


/// Member `type` is the type of the result of a binary arithmetic (or
/// bitwise) operation (+, -, *, /, %, |, &, ^) when applied to
/// operands of type `A` and `B` respectively. The type of the result
/// of a shift operation (<<, >>) can instead be found as the type
/// resulting from integral promotion of the left operand. The type of
/// the result of a unary arithmetic (or bitwise) operation can be
/// found as the type resulting from integral promotion of the
/// operand.
///
/// \note Enum types are supported only when the compiler supports the
/// C++11 'decltype' feature.
template<class A, class B> struct ArithBinOpType;


/// Member `type` is `B` if `B` has more value bits than `A`,
/// otherwise is is `A`.
template<class A, class B> struct ChooseWidestInt;


/// Member `type` is the first of `unsigned char`, `unsigned short`,
/// `unsigned int`, `unsigned long`, and `unsigned long long` that has
/// at least `bits` value bits.
template<int bits> struct LeastUnsigned;


/// Member `type` is `unsigned` if `unsigned` has at least `bits`
/// value bits, otherwise it is the same as
/// `LeastUnsigned<bits>::type`.
template<int bits> struct FastestUnsigned;





// Implementation

} // namespace util

namespace _impl {

#ifndef TIGHTDB_HAVE_CXX11_TYPE_TRAITS

template<class T> struct is_int { static const bool value = false; };
template<> struct is_int<bool>               { static const bool value = true; };
template<> struct is_int<char>               { static const bool value = true; };
template<> struct is_int<signed char>        { static const bool value = true; };
template<> struct is_int<unsigned char>      { static const bool value = true; };
template<> struct is_int<wchar_t>            { static const bool value = true; };
template<> struct is_int<short>              { static const bool value = true; };
template<> struct is_int<unsigned short>     { static const bool value = true; };
template<> struct is_int<int>                { static const bool value = true; };
template<> struct is_int<unsigned>           { static const bool value = true; };
template<> struct is_int<long>               { static const bool value = true; };
template<> struct is_int<unsigned long>      { static const bool value = true; };
template<> struct is_int<long long>          { static const bool value = true; };
template<> struct is_int<unsigned long long> { static const bool value = true; };

template<class T> struct is_float { static const bool value = false; };
template<> struct is_float<float>       { static const bool value = true; };
template<> struct is_float<double>      { static const bool value = true; };
template<> struct is_float<long double> { static const bool value = true; };

#endif // !TIGHTDB_HAVE_CXX11_TYPE_TRAITS

} // namespace _impl


namespace util {


template<class T> struct IsIntegral {
#ifdef TIGHTDB_HAVE_CXX11_TYPE_TRAITS
    static const bool value = std::is_integral<T>::value;
#else
    static const bool value = _impl::is_int<typename RemoveCV<T>::type>::value;
#endif
};


template<class T> struct IsFloatingPoint {
#ifdef TIGHTDB_HAVE_CXX11_TYPE_TRAITS
    static const bool value = std::is_floating_point<T>::value;
#else
    static const bool value = _impl::is_float<typename RemoveCV<T>::type>::value;
#endif
};


#ifdef TIGHTDB_HAVE_CXX11_DECLTYPE
template<class T> struct Promote {
    typedef decltype(+T()) type; // FIXME: This is not performing floating-point promotion.
};
#else
template<> struct Promote<bool> {
    typedef int type;
};
template<> struct Promote<char> {
private:
    static const bool cond =
        int(INT_MIN) <= int(CHAR_MIN) && unsigned(CHAR_MAX) <= unsigned(INT_MAX);
public:
    typedef CondType<cond, int, unsigned>::type type;
};
template<> struct Promote<signed char> {
    typedef int type;
};
template<> struct Promote<unsigned char> {
private:
    static const bool cond = unsigned(UCHAR_MAX) <= unsigned(INT_MAX);
public:
    typedef CondType<cond, int, unsigned>::type type;
};
template<> struct Promote<wchar_t> {
private:
    typedef intmax_t  max_int;
    typedef uintmax_t max_uint;
    static const bool cond_0 =
        (0 <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= max_uint(ULLONG_MAX));
    static const bool cond_1 =
        (max_int(LLONG_MIN) <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= max_uint(LLONG_MAX));
    static const bool cond_2 =
        (0 <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= max_uint(ULONG_MAX));
    static const bool cond_3 =
        (max_int(LONG_MIN) <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= max_uint(LONG_MAX));
    static const bool cond_4 =
        (0 <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= unsigned(UINT_MAX));
    static const bool cond_5 =
        (int(INT_MIN) <= max_int(WCHAR_MIN)) && (max_uint(WCHAR_MAX) <= unsigned(INT_MAX));
    typedef CondType<cond_0, unsigned long long, void>::type type_0;
    typedef CondType<cond_1, long long,        type_0>::type type_1;
    typedef CondType<cond_2, unsigned long,    type_1>::type type_2;
    typedef CondType<cond_3, long,             type_2>::type type_3;
    typedef CondType<cond_4, unsigned,         type_3>::type type_4;
    typedef CondType<cond_5, int,              type_4>::type type_5;
    TIGHTDB_STATIC_ASSERT(!(SameType<type_5, void>::value), "Failed to promote `wchar_t`");
public:
    typedef type_5 type;
};
template<> struct Promote<short> {
    typedef int type;
};
template<> struct Promote<unsigned short> {
private:
    static const bool cond = unsigned(USHRT_MAX) <= unsigned(INT_MAX);
public:
    typedef CondType<cond, int, unsigned>::type type;
};
template<> struct Promote<int> { typedef int type; };
template<> struct Promote<unsigned> { typedef unsigned type; };
template<> struct Promote<long> { typedef long type; };
template<> struct Promote<unsigned long> { typedef unsigned long type; };
template<> struct Promote<long long> { typedef long long type; };
template<> struct Promote<unsigned long long> { typedef unsigned long long type; };
template<> struct Promote<float> { typedef double type; };
template<> struct Promote<double> { typedef double type; };
template<> struct Promote<long double> { typedef long double type; };
#endif // !TIGHTDB_HAVE_CXX11_DECLTYPE


#ifdef TIGHTDB_HAVE_CXX11_DECLTYPE
template<class A, class B> struct ArithBinOpType {
    typedef decltype(A()+B()) type;
};
#else
template<class A, class B> struct ArithBinOpType {
private:
    typedef typename Promote<A>::type A2;
    typedef typename Promote<B>::type B2;

    typedef unsigned long long ullong;
    typedef typename CondType<ullong(UINT_MAX) <= ullong(LONG_MAX), long, unsigned long>::type type_l_u;
    typedef typename CondType<EitherTypeIs<unsigned, A2, B2>::value, type_l_u, long>::type type_l;

    typedef typename CondType<ullong(UINT_MAX) <= ullong(LLONG_MAX), long long, unsigned long long>::type type_ll_u;
    typedef typename CondType<ullong(ULONG_MAX) <= ullong(LLONG_MAX), long long, unsigned long long>::type type_ll_ul;
    typedef typename CondType<EitherTypeIs<unsigned, A2, B2>::value, type_ll_u, long long>::type type_ll_1;
    typedef typename CondType<EitherTypeIs<unsigned long, A2, B2>::value, type_ll_ul, type_ll_1>::type type_ll;

    typedef typename CondType<EitherTypeIs<unsigned, A2, B2>::value, unsigned, int>::type type_1;
    typedef typename CondType<EitherTypeIs<long, A2, B2>::value, type_l, type_1>::type type_2;
    typedef typename CondType<EitherTypeIs<unsigned long, A2, B2>::value, unsigned long, type_2>::type type_3;
    typedef typename CondType<EitherTypeIs<long long, A2, B2>::value, type_ll, type_3>::type type_4;
    typedef typename CondType<EitherTypeIs<unsigned long long, A2, B2>::value, unsigned long long, type_4>::type type_5;
    typedef typename CondType<EitherTypeIs<float, A, B>::value, float, type_5>::type type_6;
    typedef typename CondType<EitherTypeIs<double, A, B>::value, double, type_6>::type type_7;

public:
    typedef typename CondType<EitherTypeIs<long double, A, B>::value, long double, type_7>::type type;
};
#endif // !TIGHTDB_HAVE_CXX11_DECLTYPE


template<class A, class B> struct ChooseWidestInt {
private:
    typedef std::numeric_limits<A> lim_a;
    typedef std::numeric_limits<B> lim_b;
    TIGHTDB_STATIC_ASSERT(lim_a::is_specialized && lim_b::is_specialized,
                          "std::numeric_limits<> must be specialized for both types");
    TIGHTDB_STATIC_ASSERT(lim_a::is_integer && lim_b::is_integer,
                          "Both types must be integers");
public:
    typedef typename CondType<(lim_a::digits >= lim_b::digits), A, B>::type type;
};


template<int bits> struct LeastUnsigned {
private:
    typedef void                                          types_0;
    typedef TypeAppend<types_0, unsigned char>::type      types_1;
    typedef TypeAppend<types_1, unsigned short>::type     types_2;
    typedef TypeAppend<types_2, unsigned int>::type       types_3;
    typedef TypeAppend<types_3, unsigned long>::type      types_4;
    typedef TypeAppend<types_4, unsigned long long>::type types_5;
    typedef types_5 types;
    // The `dummy<>` template is there to work around a bug in
    // VisualStudio (seen in versions 2010 and 2012). Without the
    // `dummy<>` template, The C++ compiler in Visual Studio would
    // attempt to instantiate `FindType<type, pred>` before the
    // instantiation of `LeastUnsigned<>` which obviously fails
    // because `pred` depends on `bits`.
    template<int> struct dummy {
        template<class T> struct pred {
            static const bool value = std::numeric_limits<T>::digits >= bits;
        };
    };
public:
    typedef typename FindType<types, dummy<bits>::template pred>::type type;
    TIGHTDB_STATIC_ASSERT(!(SameType<type, void>::value), "No unsigned type is that wide");
};


template<int bits> struct FastestUnsigned {
private:
    typedef typename util::LeastUnsigned<bits>::type least_unsigned;
public:
    typedef typename util::ChooseWidestInt<unsigned, least_unsigned>::type type;
};


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_TYPE_TRAITS_HPP
