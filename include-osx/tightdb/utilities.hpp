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
#ifndef TIGHTDB_UTILITIES_HPP
#define TIGHTDB_UTILITIES_HPP

#include <stdint.h>
#include <cstdlib>
#include <cstdlib> // size_t
#include <algorithm>

#ifdef _MSC_VER
#  include <win32/types.h>
#  include <intrin.h>
#endif

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>
#include <tightdb/util/safe_int_ops.hpp>

// GCC defines __i386__ and __x86_64__
#if (defined(__X86__) || defined(__i386__) || defined(i386) || defined(_M_IX86) || defined(__386__) || defined(__x86_64__) || defined(_M_X64))
#  define TIGHTDB_X86_OR_X64
#  define TIGHTDB_X86_OR_X64_TRUE true
#else
#  define TIGHTDB_X86_OR_X64_TRUE false
#endif

// GCC defines __arm__
#ifdef __arm__
#  define TIGHTDB_ARCH_ARM
#endif

#if defined _LP64 || defined __LP64__ || defined __64BIT__ || _ADDR64 || defined _WIN64 || defined __arch64__ || __WORDSIZE == 64 || (defined __sparc && defined __sparcv9) || defined __x86_64 || defined __amd64 || defined __x86_64__ || defined _M_X64 || defined _M_IA64 || defined __ia64 || defined __IA64__
#  define TIGHTDB_PTR_64
#endif


#if defined(TIGHTDB_PTR_64) && defined(TIGHTDB_X86_OR_X64)
#  define TIGHTDB_COMPILER_SSE  // Compiler supports SSE 4.2 through __builtin_ accessors or back-end assembler
#  define TIGHTDB_COMPILER_AVX
#endif

namespace tightdb {

typedef bool(*StringCompareCallback)(const char* string1, const char* string2);

extern signed char sse_support;
extern signed char avx_support;

template<int version> TIGHTDB_FORCEINLINE bool sseavx()
{
/*
    Return wether or not SSE 3.0 (if version = 30) or 4.2 (for version = 42) is supported. Return value
    is based on the CPUID instruction.

    sse_support = -1: No SSE support
    sse_support = 0: SSE3
    sse_support = 1: SSE42

    avx_support = -1: No AVX support
    avx_support = 0: AVX1 supported
    sse_support = 1: AVX2 supported (not yet implemented for detection in our cpuid_init(), todo)

    This lets us test very rapidly at runtime because we just need 1 compare instruction (with 0) to test both for
    SSE 3 and 4.2 by caller (compiler optimizes if calls are concecutive), and can decide branch with ja/jl/je because
    sse_support is signed type. Also, 0 requires no immediate operand. Same for AVX.

    We runtime-initialize sse_support in a constructor of a static variable which is not guaranteed to be called
    prior to cpu_sse(). So we compile-time initialize sse_support to -2 as fallback.
*/
    TIGHTDB_STATIC_ASSERT(version == 1 || version == 2 || version == 30 || version == 42, "Only version == 1 (AVX), 2 (AVX2), 30 (SSE 3) and 42 (SSE 4.2) are supported for detection");
#ifdef TIGHTDB_COMPILER_SSE
    if (version == 30)
        return (sse_support >= 0);
    else if (version == 42)
        return (sse_support > 0);   // faster than == 1 (0 requres no immediate operand)
    else if (version == 1) // avx
        return (avx_support >= 0);
    else if (version == 2) // avx2
        return (avx_support > 0);

#else
    return false;
#endif
}

typedef struct {
    unsigned long long remainder;
    unsigned long long remainder_len;
    unsigned long long b_val;
    unsigned long long a_val;
    unsigned long long result;
} checksum_t;

void cpuid_init();
unsigned long long checksum(unsigned char* data, size_t len);
void checksum_rolling(unsigned char* data, size_t len, checksum_t* t);
void* round_up(void* p, size_t align);
void* round_down(void* p, size_t align);
size_t round_up(size_t p, size_t align);
size_t round_down(size_t p, size_t align);
void checksum_init(checksum_t* t);

// popcount
int fast_popcount32(int32_t x);
int fast_popcount64(int64_t x);



// Implementation:

// Safe cast from 64 to 32 bits on 32 bit architecture. Differs from to_ref() by not testing alignment and REF-bitflag.
inline std::size_t to_size_t(int_fast64_t v) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(!util::int_cast_has_overflow<std::size_t>(v));
    return std::size_t(v);
}


template<typename ReturnType, typename OriginalType>
ReturnType type_punning(OriginalType variable) TIGHTDB_NOEXCEPT
{
    union Both {
        OriginalType in;
        ReturnType out;
    };
    Both both;
    both.out = ReturnType(); // Clear all bits in case ReturnType is larger than OriginalType
    both.in = variable;
    return both.out;
}

enum FindRes {
    FindRes_not_found,
    FindRes_single,
    FindRes_column
};

enum IndexMethod {
    index_FindFirst,
    index_FindAll,
    index_FindAll_nocopy,
    index_Count
};


// Use safe_equal() instead of std::equal() when comparing sequences which can have a 0 elements.
template <class InputIterator1, class InputIterator2>
bool safe_equal(InputIterator1 first1, InputIterator1 last1, InputIterator2 first2)
{
#if defined(_MSC_VER) && defined(_DEBUG)

    // Windows has a special check in debug mode against passing null
    // pointer to std::equal(). It's uncertain if this is allowed by the C++ standard. For details, see
    // http://stackoverflow.com/questions/19120779/is-char-p-0-stdequalp-p-p-well-defined-according-to-the-c-standard.
    // Below check 'first1==last1' is to prevent failure in debug mode.
    return (first1 == last1 || std::equal(first1, last1, first2));
#else
    return std::equal(first1, last1, first2);
#endif
}

// Emulates nullptr of C++11
const class {
public:
    template<class T> operator T*() const
    {
        return 0;
    }
    template<class C, class T> operator T C::*() const
    {
        return 0;
    }
private:
    void operator& () const;
} null_ptr = {};


template<class T> struct Wrap {
    Wrap(const T& v): m_value(v) {}
    operator T() const { return m_value; }
private:
    T m_value;
};


} // namespace tightdb

#endif // TIGHTDB_UTILITIES_HPP

