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
#ifndef TIGHTDB_UTIL_UNICODE_HPP
#define TIGHTDB_UTIL_UNICODE_HPP

#include <stdint.h>
#include <string>

#include <tightdb/util/safe_int_ops.hpp>
#include <tightdb/string_data.hpp>
#include <tightdb/util/features.h>
#include <tightdb/utilities.hpp>

#if TIGHTDB_HAVE_CXX11
    #include <locale>
#endif

namespace tightdb {

    enum string_compare_method_t { STRING_COMPARE_CORE, STRING_COMPARE_CPP11, STRING_COMPARE_CALLBACK } ;

    extern StringCompareCallback string_compare_callback;
    extern string_compare_method_t string_compare_method;

    // Description for set_string_compare_method():
    //
    // Short summary: iOS language binding: call 
    //     set_string_compare_method() for fast but slightly inaccurate sort in some countries, or
    //     set_string_compare_method(2, callbackptr) for slow but precise sort (see callbackptr below)
    //
    // Different countries ('locales') have different sorting order for strings and letters. Because there unfortunatly 
    // doesn't exist any unified standardized way to compare strings in C++ on multiple platforms, we need this method.
    //
    // It determins how sorting a TableView by a String column must take place. The 'method' argument can be:
    //
    // 0: Fast core-only compare (no OS/framework calls). LIMITATIONS: Works only upto 'Latin Extended 2' (unicodes 
    // 0...591). Also, sorting order is according to 'en_US' so it may be slightly inaccurate for some countries.
    // 'callback' argument is ignored. 
    //
    // Return value: Always 'true'
    //
    // 1: Native C++11 method if core is compiled as C++11. Gives precise sorting according 
    // to user's current locale. LIMITATIONS: Currently works only on Windows and on Linux with clang. Does NOT work on 
    // iOS (due to only 'C' locale being available in CoreFoundation, which puts 'Z' before 'a'). Unknown if works on 
    // Windows Phone / Android. Furthermore it does NOT work on Linux with gcc 4.7 or 4.8 (lack of c++11 feature that 
    // can convert utf8->wstring without calls to setlocale()). 
    //
    // Return value: 'true' if supported, otherwise 'false' (if so, then previous setting, if any, is preserved).
    //
    // 2: Callback method. Language binding / C++ user must provide a utf-8 callback method of prototype: 
    // bool callback(const char* string1, const char* string2) where 'callback' must return bool(string1 < string2).
    //
    // Return value: Always 'true'
    // 
    // Default is method = 0 if the function is never called
    //
    // NOT THREAD SAFE! Call once during initialization or make sure it's not called simultaneously with different arguments
    // The setting is remembered per-process; it does NOT need to be called prior to each sort
    bool set_string_compare_method(string_compare_method_t method, StringCompareCallback callback);


    // Return size in bytes of utf8 character. No error checking
    size_t sequence_length(char lead);

    // Return bool(string1 < string2)
    bool utf8_compare(StringData string1, StringData string2);

    // Return unicode value of character. 
    uint32_t utf8value(const char* character);

    inline bool equal_sequence(const char*& begin, const char* end, const char* begin2);

    // FIXME: The current approach to case insensitive comparison requires
    // that case mappings can be done in a way that does not change he
    // number of bytes used to encode the individual Unicode
    // character. This is not generally the case, so, as far as I can see,
    // this approach has no future.
    //
    // FIXME: The current approach to case insensitive comparison relies
    // on checking each "haystack" character against the corresponding
    // character in both a lower cased and an upper cased version of the
    // "needle". While this leads to efficient comparison, it ignores the
    // fact that "case folding" is the only correct approach to case
    // insensitive comparison in a locale agnostic Unicode
    // environment.
    //
    // See
    //   http://www.w3.org/International/wiki/Case_folding
    //   http://userguide.icu-project.org/transforms/casemappings#TOC-Case-Folding.
    //
    // The ideal API would probably be something like this:
    //
    //   case_fold:        utf_8 -> case_folded
    //   equal_case_fold:  (needle_case_folded, single_haystack_entry_utf_8) -> found
    //   search_case_fold: (needle_case_folded, huge_haystack_string_utf_8) -> found_at_position
    //
    // The case folded form would probably be using UTF-32 or UTF-16.


    /// If successfull, writes a string to \a target of the same size as
    /// \a source, and returns true. Returns false if invalid UTF-8
    /// encoding was encountered.
    bool case_map(StringData source, char* target, bool upper);

    /// Assumes that the sizes of \a needle_upper and \a needle_lower are
    /// identical to the size of \a haystack. Returns false if the needle
    /// is different from the haystack.
    bool equal_case_fold(StringData haystack, const char* needle_upper, const char* needle_lower);

    /// Assumes that the sizes of \a needle_upper and \a needle_lower are
    /// both equal to \a needle_size. Returns haystack.size() if the
    /// needle was not found.
    std::size_t search_case_fold(StringData haystack, const char* needle_upper,
        const char* needle_lower, std::size_t needle_size);


} // namespace tightdb

#endif // TIGHTDB_UTIL_UTF8_HPP
