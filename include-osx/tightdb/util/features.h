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
 *************************************************************************/
#ifndef TIGHTDB_UTIL_FEATURES_H
#define TIGHTDB_UTIL_FEATURES_H


#ifdef TIGHTDB_HAVE_CONFIG
#  include <tightdb/util/config.h>
#else
#  define TIGHTDB_VERSION "unknown"
#  ifndef _WIN32
#    define TIGHTDB_INSTALL_PREFIX      "/usr/local"
#    define TIGHTDB_INSTALL_EXEC_PREFIX TIGHTDB_INSTALL_PREFIX
#    define TIGHTDB_INSTALL_INCLUDEDIR  TIGHTDB_INSTALL_PREFIX "/include"
#    define TIGHTDB_INSTALL_BINDIR      TIGHTDB_INSTALL_EXEC_PREFIX "/bin"
#    define TIGHTDB_INSTALL_LIBDIR      TIGHTDB_INSTALL_EXEC_PREFIX "/lib"
#    define TIGHTDB_INSTALL_LIBEXECDIR  TIGHTDB_INSTALL_EXEC_PREFIX "/libexec"
#  endif
#endif



/* The maximum number of elements in a B+-tree node. Applies to inner nodes and
 * to leaves. The minimum allowable value is 2.
 */
#ifndef TIGHTDB_MAX_BPNODE_SIZE
#  define TIGHTDB_MAX_BPNODE_SIZE 1000
#endif



#if __cplusplus >= 201103 || __GXX_EXPERIMENTAL_CXX0X__ || _MSC_VER >= 1700
#  define TIGHTDB_HAVE_CXX11 1
#endif


/* See these links for information about feature check macroes in GCC,
 * Clang, and MSVC:
 *
 * http://gcc.gnu.org/projects/cxx0x.html
 * http://clang.llvm.org/cxx_status.html
 * http://clang.llvm.org/docs/LanguageExtensions.html#checks-for-standard-language-features
 * http://msdn.microsoft.com/en-us/library/vstudio/hh567368.aspx
 * http://sourceforge.net/p/predef/wiki/Compilers
 */


/* Compiler is GCC and version is greater than or equal to the specified version */
#define TIGHTDB_HAVE_AT_LEAST_GCC(maj, min) \
    (__GNUC__ > (maj) || __GNUC__ == (maj) && __GNUC_MINOR__ >= (min))

#if __clang__
#  define TIGHTDB_HAVE_CLANG_FEATURE(feature) __has_feature(feature)
#else
#  define TIGHTDB_HAVE_CLANG_FEATURE(feature) 0
#endif

/* Compiler is MSVC (Microsoft Visual C++) */
#if _MSC_VER >= 1600
#  define TIGHTDB_HAVE_AT_LEAST_MSVC_10_2010 1
#endif
#if _MSC_VER >= 1700
#  define TIGHTDB_HAVE_AT_LEAST_MSVC_11_2012 1
#endif
#if _MSC_VER >= 1800
#  define TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013 1
#endif


/* Support for C++11 <type_traits>. */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 3) || \
    TIGHTDB_HAVE_CXX11 && _LIBCPP_VERSION >= 1001 || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_10_2010
#  define TIGHTDB_HAVE_CXX11_TYPE_TRAITS 1
#endif


/* Support for C++11 <atomic>.
 *
 * FIXME: Somehow MSVC 11 (2012) fails when <atomic> is included in thread.cpp. */
#  if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 4) || \
    TIGHTDB_HAVE_CXX11 && _LIBCPP_VERSION >= 1001 || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013
#    define TIGHTDB_HAVE_CXX11_ATOMIC 1
#  endif


/* Support for C++11 variadic templates. */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 3) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_variadic_templates) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013
#  define TIGHTDB_HAVE_CXX11_VARIADIC_TEMPLATES 1
#endif


/* Support for C++11 static_assert(). */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 3) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_static_assert) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_10_2010
#  define TIGHTDB_HAVE_CXX11_STATIC_ASSERT 1
#endif


/* Support for C++11 r-value references and std::move().
 *
 * NOTE: Not yet fully supported in MSVC++ 12 (2013). */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC_4_3 || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_rvalue_references) && _LIBCPP_VERSION >= 1001
#  define TIGHTDB_HAVE_CXX11_RVALUE_REFERENCE 1
#endif


/* Support for the C++11 'decltype' keyword. */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 3) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_decltype) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013
#  define TIGHTDB_HAVE_CXX11_DECLTYPE 1
#endif


/* Support for C++11 initializer lists. */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 4) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_generalized_initializers) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013
#  define TIGHTDB_HAVE_CXX11_INITIALIZER_LISTS 1
#endif


/* Support for C++11 explicit conversion operators. */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 5) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_explicit_conversions) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_12_2013
#  define TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS 1
#endif


/* Support for the C++11 'constexpr' keyword.
 *
 * NOTE: Not yet fully supported in MSVC++ 12 (2013). */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 6) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_constexpr)
#  define TIGHTDB_HAVE_CXX11_CONSTEXPR 1
#endif
#if TIGHTDB_HAVE_CXX11_CONSTEXPR
#  define TIGHTDB_CONSTEXPR constexpr
#else
#  define TIGHTDB_CONSTEXPR
#endif


/* Support for the C++11 'noexcept' specifier.
 *
 * NOTE: Not yet fully supported in MSVC++ 12 (2013). */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 6) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_noexcept)
#  define TIGHTDB_HAVE_CXX11_NOEXCEPT 1
#endif
#if TIGHTDB_HAVE_CXX11_NOEXCEPT
#  define TIGHTDB_NOEXCEPT noexcept
#elif defined TIGHTDB_DEBUG
#  define TIGHTDB_NOEXCEPT throw()
#else
#  define TIGHTDB_NOEXCEPT
#endif
#if TIGHTDB_HAVE_CXX11_NOEXCEPT
#  define TIGHTDB_NOEXCEPT_IF(cond) noexcept (cond)
#else
#  define TIGHTDB_NOEXCEPT_IF(cond)
#endif
#if TIGHTDB_HAVE_CXX11_NOEXCEPT
#  define TIGHTDB_NOEXCEPT_OR_NOTHROW noexcept
#else
#  define TIGHTDB_NOEXCEPT_OR_NOTHROW throw ()
#endif


/* Support for C++11 explicit virtual overrides */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 7) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_override_control) || \
    TIGHTDB_HAVE_AT_LEAST_MSVC_11_2012
#  define TIGHTDB_OVERRIDE override
#else
#  define TIGHTDB_OVERRIDE
#endif


/* The way to specify that a function never returns.
 *
 * NOTE: C++11 generalized attributes are not yet fully supported in
 * MSVC++ 12 (2013). */
#if TIGHTDB_HAVE_CXX11 && TIGHTDB_HAVE_AT_LEAST_GCC(4, 8) || \
    TIGHTDB_HAVE_CLANG_FEATURE(cxx_attributes)
#  define TIGHTDB_NORETURN [[noreturn]]
#elif __GNUC__
#  define TIGHTDB_NORETURN __attribute__((noreturn))
#elif _MSC_VER
#  define TIGHTDB_NORETURN __declspec(noreturn)
#else
#  define TIGHTDB_NORETURN
#endif


/* The way to specify that a variable or type is intended to possibly
 * not be used. Use it to suppress a warning from the compiler. */
#if __GNUC__
#  define TIGHTDB_UNUSED __attribute__((unused))
#else
#  define TIGHTDB_UNUSED
#endif


#if __GNUC__ || defined __INTEL_COMPILER
#  define TIGHTDB_UNLIKELY(expr) __builtin_expect(!!(expr), 0)
#  define TIGHTDB_LIKELY(expr)   __builtin_expect(!!(expr), 1)
#else
#  define TIGHTDB_UNLIKELY(expr) (expr)
#  define TIGHTDB_LIKELY(expr)   (expr)
#endif


#if defined(__GNUC__) || defined(__HP_aCC)
    #define TIGHTDB_FORCEINLINE inline __attribute__((always_inline))
#elif defined(_MSC_VER)
    #define TIGHTDB_FORCEINLINE __forceinline
#else
    #define TIGHTDB_FORCEINLINE inline
#endif


#if defined ANDROID
#  define TIGHTDB_ANDROID 1
#endif


#if defined __APPLE__ && defined __MACH__
/* Apple OSX and iOS (Darwin). */
#  include <TargetConditionals.h>
#  if TARGET_OS_IPHONE == 1
/* Device (iPhone or iPad) or simulator. */
#    define TIGHTDB_IOS 1
#  endif
#endif


#if TIGHTDB_ANDROID || TIGHTDB_IOS
#  define TIGHTDB_MOBILE 1
#endif


#endif /* TIGHTDB_UTIL_FEATURES_H */
