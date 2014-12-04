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
#ifndef TIGHTDB_UTIL_SAFE_INT_OPS_HPP
#define TIGHTDB_UTIL_SAFE_INT_OPS_HPP

#include <limits>

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>
#include <tightdb/util/meta.hpp>
#include <tightdb/util/type_traits.hpp>

namespace tightdb {
namespace util {


/// Perform integral or floating-point promotion on the argument. This
/// is useful for example when printing a number of arbitrary numeric
/// type to 'stdout', since it will convert values of character-like
/// types to regular integer types, which will then be printed as
/// numbers rather characters.
template<class T> typename Promote<T>::type promote(T value) TIGHTDB_NOEXCEPT;


/// This function allows you to test for a negative value in any
/// numeric type, even when the type is unsigned. Normally, when the
/// type is unsigned, such a test will produce a compiler warning.
template<class T> bool is_negative(T value) TIGHTDB_NOEXCEPT;


/// Cast the specified value to the specified unsigned type reducing
/// the value (or in case of negative values, the two's complement
/// representation) modulo `2**N` where `N` is the number of value
/// bits (or digits) in the unsigned target type. This is usefull in
/// cases where the target type may be `bool`, but need not be `bool`.
template<class To, class From> To cast_to_unsigned(From) TIGHTDB_NOEXCEPT;


//@{

/// Compare two integers of the same, or of different type, and
/// produce the expected result according to the natural
/// interpretation of the operation.
///
/// Note that in general a standard comparison between a signed and an
/// unsigned integer type is unsafe, and it often generates a compiler
/// warning. An example is a 'less than' comparison between a negative
/// value of type 'int' and a small positive value of type
/// 'unsigned'. In this case the negative value will be converted to
/// 'unsigned' producing a large positive value which, in turn, will
/// lead to the counter intuitive result of 'false'.
///
/// Please note that these operation incur absolutely no overhead when
/// the two types have the same signedness.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
///
/// These functions make absolutely no assumptions about the platform
/// except that it complies with at least C++03.

template<class A, class B> inline bool int_equal_to(A,B) TIGHTDB_NOEXCEPT;
template<class A, class B> inline bool int_not_equal_to(A,B) TIGHTDB_NOEXCEPT;
template<class A, class B> inline bool int_less_than(A,B) TIGHTDB_NOEXCEPT;
template<class A, class B> inline bool int_less_than_or_equal(A,B) TIGHTDB_NOEXCEPT;
template<class A, class B> inline bool int_greater_than(A,B) TIGHTDB_NOEXCEPT;
template<class A, class B> inline bool int_greater_than_or_equal(A,B) TIGHTDB_NOEXCEPT;

//@}


//@{

/// Check for overflow in integer variable `lval` while adding integer
/// `rval` to it, or while subtracting integer `rval` from it. Returns
/// true on positive or negative overflow.
///
/// Both `lval` and `rval` must be of an integer type for which a
/// specialization of std::numeric_limits<> exists. The two types need
/// not be the same, in particular, one can be signed and the other
/// one can be unsigned.
///
/// These functions are especially well suited for cases where \a rval
/// is a compile-time constant.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
///
/// These functions make absolutely no assumptions about the platform
/// except that it complies with at least C++03.

template<class L, class R>
inline bool int_add_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT;

template<class L, class R>
inline bool int_subtract_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT;

//@}


/// Check for positive overflow when multiplying two positive integers
/// of the same, or of different type. Returns true on overflow.
///
/// \param lval Must not be negative. Both signed and unsigned types
/// can be used.
///
/// \param rval Must be stricly greater than zero. Both signed and
/// unsigned types can be used.
///
/// This function is especially well suited for cases where \a rval is
/// a compile-time constant.
///
/// This function checks at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
///
/// This function makes absolutely no assumptions about the platform
/// except that it complies with at least C++03.
template<class L, class R>
inline bool int_multiply_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT;


/// Checks for positive overflow when performing a bitwise shift to
/// the left on a non-negative value of arbitrary integer
/// type. Returns true on overflow.
///
/// \param lval Must not be negative. Both signed and unsigned types
/// can be used.
///
/// \param i Must be non-negative and such that <tt>L(1)>>i</tt> has a
/// value that is defined by the C++03 standard.
///
/// This function makes absolutely no assumptions about the platform
/// except that it complies with at least C++03.
template<class T> inline bool int_shift_left_with_overflow_detect(T& lval, int i) TIGHTDB_NOEXCEPT;


//@{

/// Check for overflow when casting an integer value from one type to
/// another. While the first function is a mere check, the second one
/// also carries out the cast, but only when there is no
/// overflow. Both return true on overflow.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
///
/// These functions make absolutely no assumptions about the platform
/// except that it complies with at least C++03.

template<class To, class From>
bool int_cast_has_overflow(From from) TIGHTDB_NOEXCEPT;

template<class To, class From>
bool int_cast_with_overflow_detect(From from, To& to) TIGHTDB_NOEXCEPT;

//@}


/// Convert negative values from two's complement representation to
/// the platforms native representation.
///
/// If `To` is an unsigned type, this function is does nothing beyond
/// casting the specified value to `To`. Otherwise, `To` is a signed
/// type, and negative values will be converted from two's complement
/// representation in unsigned `From` to the platforms native
/// representation in `To`.
///
/// For signed `To` the result is well-defined if, and only if the
/// value with the specified two's complement representation is
/// representable in the specified signed type. While this is
/// generally the case when using corresponding signed/unsigned type
/// pairs, it is not guaranteed by the standard. However, if you know
/// that the signed type has at least as many value bits as the
/// unsigned type, then the result is always well-defined. Note that a
/// 'value bit' in this context is the same as a 'digit' from the
/// point of view of `std::numeric_limits`.
///
/// On platforms that use two's complement representation of negative
/// values, this function is expected to be completely optimized
/// away. This has been observed to be true with both GCC 4.8 and
/// Clang 3.2.
///
/// Note that the **opposite** direction (from the platforms native
/// representation to two's complement) is trivially handled by
/// casting the signed value to a value of a sufficiently wide
/// unsigned integer type. An unsigned type will be sufficiently wide
/// if it has at least one more value bit than the signed type.
///
/// Interestingly, the C++ language offers no direct way of doing what
/// this function does, yet, this function is implemented in a way
/// that makes no assumption about the underlying platform except what
/// is guaranteed by C++11.
///
/// \tparam From The unsigned type used to store the two's complement
/// representation.
///
/// \tparam To A signed or unsigned integer type.
template<class To, class From> To from_twos_compl(From twos_compl) TIGHTDB_NOEXCEPT;






// Implementation:

template<class T> inline typename Promote<T>::type promote(T value) TIGHTDB_NOEXCEPT
{
    typedef typename Promote<T>::type promoted_type;
    promoted_type value_2 = promoted_type(value);
    return value_2;
}

} // namespace util

namespace _impl {

template<class T, bool is_signed> struct IsNegative {
    static bool test(T value) TIGHTDB_NOEXCEPT
    {
        return value < 0;
    }
};
template<class T> struct IsNegative<T, false> {
    static bool test(T) TIGHTDB_NOEXCEPT
    {
        return false;
    }
};

template<class To> struct CastToUnsigned {
    template<class From> static To cast(From value) TIGHTDB_NOEXCEPT
    {
        return To(value);
    }
};
template<> struct CastToUnsigned<bool> {
    template<class From> static bool cast(From value) TIGHTDB_NOEXCEPT
    {
        return bool(unsigned(value) & 1);
    }
};

template<class L, class R, bool l_signed, bool r_signed> struct SafeIntBinopsImpl {};

// (unsigned, unsigned) (all size combinations)
//
// This implementation utilizes the fact that overflow in unsigned
// arithmetic is guaranteed to be handled by reduction modulo 2**N
// where N is the number of bits in the unsigned type. The purpose of
// the bitwise 'and' with lim_l::max() is to make a cast to bool
// behave the same way as casts to other unsigned integer types.
// Finally, this implementation uses the fact that if modular addition
// overflows, then the result must be a value that is less than both
// operands. Also, if modular subtraction overflows, then the result
// must be a value that is greater than the first operand.
template<class L, class R> struct SafeIntBinopsImpl<L, R, false, false> {
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    static const int needed_bits_l = lim_l::digits;
    static const int needed_bits_r = lim_r::digits;
    static const int needed_bits = needed_bits_l >= needed_bits_r ? needed_bits_l : needed_bits_r;
    typedef typename util::FastestUnsigned<needed_bits>::type common_unsigned;
    static bool equal(L l, R r) TIGHTDB_NOEXCEPT
    {
        return common_unsigned(l) == common_unsigned(r);
    }
    static bool less(L l, R r) TIGHTDB_NOEXCEPT
    {
        return common_unsigned(l) < common_unsigned(r);
    }
    static bool add(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        L lval_2 = util::cast_to_unsigned<L>(lval + rval);
        bool overflow = common_unsigned(lval_2) < common_unsigned(rval);
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = lval_2;
        return false;
    }
    static bool sub(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        common_unsigned lval_2 = common_unsigned(lval) - common_unsigned(rval);
        bool overflow = lval_2 > common_unsigned(lval);
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = util::cast_to_unsigned<L>(lval_2);
        return false;
    }
};

// (unsigned, signed) (all size combinations)
template<class L, class R> struct SafeIntBinopsImpl<L, R, false, true> {
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    static const int needed_bits_l = lim_l::digits;
    static const int needed_bits_r = lim_r::digits + 1;
    static const int needed_bits = needed_bits_l >= needed_bits_r ? needed_bits_l : needed_bits_r;
    typedef typename util::FastestUnsigned<needed_bits>::type common_unsigned;
    typedef std::numeric_limits<common_unsigned> lim_cu;
    static bool equal(L l, R r) TIGHTDB_NOEXCEPT
    {
        return (lim_l::digits > lim_r::digits) ?
            r >= 0 && l == util::cast_to_unsigned<L>(r) : R(l) == r;
    }
    static bool less(L l, R r) TIGHTDB_NOEXCEPT
    {
        return (lim_l::digits > lim_r::digits) ?
            r >= 0 && l < util::cast_to_unsigned<L>(r) : R(l) < r;
    }
    static bool add(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        common_unsigned lval_2 = lval + common_unsigned(rval);
        bool overflow;
        if (lim_l::digits < lim_cu::digits) {
            overflow = common_unsigned(lval_2) > common_unsigned(lim_l::max());
        }
        else {
            overflow = (lval_2 < common_unsigned(lval)) == (rval >= 0);
        }
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = util::cast_to_unsigned<L>(lval_2);
        return false;
    }
    static bool sub(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        common_unsigned lval_2 = lval - common_unsigned(rval);
        bool overflow;
        if (lim_l::digits < lim_cu::digits) {
            overflow = common_unsigned(lval_2) > common_unsigned(lim_l::max());
        }
        else {
            overflow = (common_unsigned(lval_2) > common_unsigned(lval)) == (rval >= 0);
        }
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = util::cast_to_unsigned<L>(lval_2);
        return false;
    }
};

// (signed, unsigned) (all size combinations)
template<class L, class R> struct SafeIntBinopsImpl<L, R, true, false> {
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    static const int needed_bits_l = lim_l::digits + 1;
    static const int needed_bits_r = lim_r::digits;
    static const int needed_bits = needed_bits_l >= needed_bits_r ? needed_bits_l : needed_bits_r;
    typedef typename util::FastestUnsigned<needed_bits>::type common_unsigned;
    static bool equal(L l, R r) TIGHTDB_NOEXCEPT
    {
        return (lim_l::digits < lim_r::digits) ?
            l >= 0 && util::cast_to_unsigned<R>(l) == r : l == L(r);
    }
    static bool less(L l, R r) TIGHTDB_NOEXCEPT
    {
        return (lim_l::digits < lim_r::digits) ?
            l < 0 || util::cast_to_unsigned<R>(l) < r : l < L(r);
    }
    static bool add(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        common_unsigned max_add = common_unsigned(lim_l::max()) - common_unsigned(lval);
        bool overflow = common_unsigned(rval) > max_add;
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = util::from_twos_compl<L>(common_unsigned(lval) + rval);
        return false;
    }
    static bool sub(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        common_unsigned max_sub = common_unsigned(lval) - common_unsigned(lim_l::min());
        bool overflow = common_unsigned(rval) > max_sub;
        if (TIGHTDB_UNLIKELY(overflow))
            return true;
        lval = util::from_twos_compl<L>(common_unsigned(lval) - rval);
        return false;
    }
};

// (signed, signed) (all size combinations)
template<class L, class R> struct SafeIntBinopsImpl<L, R, true, true> {
    typedef std::numeric_limits<L> lim_l;
    static bool equal(L l, R r) TIGHTDB_NOEXCEPT
    {
        return l == r;
    }
    static bool less(L l, R r) TIGHTDB_NOEXCEPT
    {
        return l < r;
    }
    static bool add(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        // Note that both subtractions below occur in a signed type
        // that is at least as wide as both of the two types. Note
        // also that any signed type guarantees that there is no
        // overflow when subtracting two negative values or two
        // non-negative value. See C99 (adopted as subset of C++11)
        // section 6.2.6.2 "Integer types" paragraph 2.
        if (rval < 0) {
            if (TIGHTDB_UNLIKELY(lval < lim_l::min() - rval))
                return true;
        }
        else {
            if (TIGHTDB_UNLIKELY(lval > lim_l::max() - rval))
                return true;
        }
        // The following statement has exactly the same effect as
        // `lval += rval`.
        lval = L(lval + rval);
        return false;
    }
    static bool sub(L& lval, R rval) TIGHTDB_NOEXCEPT
    {
        // Note that both subtractions below occur in a signed type
        // that is at least as wide as both of the two types. Note
        // also that there can be no overflow when adding a negative
        // value to a non-negative value, or when adding a
        // non-negative value to a negative one.
        if (rval < 0) {
            if (TIGHTDB_UNLIKELY(lval > lim_l::max() + rval))
                return true;
        }
        else {
            if (TIGHTDB_UNLIKELY(lval < lim_l::min() + rval))
                return true;
        }
        // The following statement has exactly the same effect as
        // `lval += rval`.
        lval = L(lval - rval);
        return false;
    }
};

template<class L, class R>
struct SafeIntBinops: SafeIntBinopsImpl<L, R, std::numeric_limits<L>::is_signed,
                                        std::numeric_limits<R>::is_signed>
{
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    TIGHTDB_STATIC_ASSERT(lim_l::is_specialized && lim_r::is_specialized,
                          "std::numeric_limits<> must be specialized for both types");
    TIGHTDB_STATIC_ASSERT(lim_l::is_integer && lim_r::is_integer,
                          "Both types must be integers");
};

} // namespace _impl

namespace util {

template<class T> inline bool is_negative(T value) TIGHTDB_NOEXCEPT
{
    return _impl::IsNegative<T, std::numeric_limits<T>::is_signed>::test(value);
}

template<class To, class From> inline To cast_to_unsigned(From value) TIGHTDB_NOEXCEPT
{
	return _impl::CastToUnsigned<To>::cast(value);
}

template<class A, class B> inline bool int_equal_to(A a, B b) TIGHTDB_NOEXCEPT
{
    return _impl::SafeIntBinops<A,B>::equal(a,b);
}

template<class A, class B> inline bool int_not_equal_to(A a, B b) TIGHTDB_NOEXCEPT
{
    return !_impl::SafeIntBinops<A,B>::equal(a,b);
}

template<class A, class B> inline bool int_less_than(A a, B b) TIGHTDB_NOEXCEPT
{
    return _impl::SafeIntBinops<A,B>::less(a,b);
}

template<class A, class B> inline bool int_less_than_or_equal(A a, B b) TIGHTDB_NOEXCEPT
{
    return !_impl::SafeIntBinops<B,A>::less(b,a); // Not greater than
}

template<class A, class B> inline bool int_greater_than(A a, B b) TIGHTDB_NOEXCEPT
{
    return _impl::SafeIntBinops<B,A>::less(b,a);
}

template<class A, class B> inline bool int_greater_than_or_equal(A a, B b) TIGHTDB_NOEXCEPT
{
    return !_impl::SafeIntBinops<A,B>::less(a,b); // Not less than
}

template<class L, class R>
inline bool int_add_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT
{
    return _impl::SafeIntBinops<L,R>::add(lval, rval);
}

template<class L, class R>
inline bool int_subtract_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT
{
    return _impl::SafeIntBinops<L,R>::sub(lval, rval);
}

template<class L, class R>
inline bool int_multiply_with_overflow_detect(L& lval, R rval) TIGHTDB_NOEXCEPT
{
    // FIXME: Check if the following optimizes better (if it works at all):
    // L lval_2 = L(lval * rval);
    // bool overflow  =  rval != 0  &&  (lval_2 / rval) != lval;
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    TIGHTDB_STATIC_ASSERT(lim_l::is_specialized && lim_r::is_specialized,
                          "std::numeric_limits<> must be specialized for both types");
    TIGHTDB_STATIC_ASSERT(lim_l::is_integer && lim_r::is_integer,
                          "Both types must be integers");
    TIGHTDB_ASSERT(int_greater_than_or_equal(lval, 0));
    TIGHTDB_ASSERT(int_greater_than(rval, 0));
    if (int_less_than(lim_r::max() / rval, lval))
        return true;
    lval = L(lval * rval);
    return false;
}

template<class T>
inline bool int_shift_left_with_overflow_detect(T& lval, int i) TIGHTDB_NOEXCEPT
{
    typedef std::numeric_limits<T> lim;
    TIGHTDB_STATIC_ASSERT(lim::is_specialized,
                          "std::numeric_limits<> must be specialized for T");
    TIGHTDB_STATIC_ASSERT(lim::is_integer,
                          "T must be an integer type");
    TIGHTDB_ASSERT(int_greater_than_or_equal(lval, 0));
    if ((lim::max() >> i) < lval)
        return true;
    lval <<= i;
    return false;
}

template<class To, class From>
inline bool int_cast_has_overflow(From from) TIGHTDB_NOEXCEPT
{
    typedef std::numeric_limits<To> lim_to;
    return int_less_than(from, lim_to::min()) || int_less_than(lim_to::max(), from);
}

template<class To, class From>
inline bool int_cast_with_overflow_detect(From from, To& to) TIGHTDB_NOEXCEPT
{
    if (TIGHTDB_LIKELY(!int_cast_has_overflow<To>(from))) {
        to = To(from);
        return false;
    }
    return true;
}

template<class To, class From> inline To from_twos_compl(From twos_compl) TIGHTDB_NOEXCEPT
{
    typedef std::numeric_limits<From> lim_f;
    typedef std::numeric_limits<To>   lim_t;
    TIGHTDB_STATIC_ASSERT(lim_f::is_specialized && lim_t::is_specialized,
                          "std::numeric_limits<> must be specialized for both types");
    TIGHTDB_STATIC_ASSERT(lim_f::is_integer && lim_t::is_integer,
                          "Both types must be integers");
    TIGHTDB_STATIC_ASSERT(!lim_f::is_signed, "`From` must be unsigned");
    To native;
    int sign_bit_pos = lim_f::digits - 1;
    From sign_bit = From(1) << sign_bit_pos;
    bool non_negative = !lim_t::is_signed || (twos_compl & sign_bit) == 0;
    if (non_negative) {
        // Non-negative value
        native = To(twos_compl);
    }
    else {
        // Negative value
        native = To(-1 - To(From(-1) - twos_compl));
    }
    return native;
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_SAFE_INT_OPS_HPP
