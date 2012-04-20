#ifndef UTF8_H
#define UTF8_H

#include <string>
#include <memory.h>
#if defined(_WIN32) || defined(__WIN32__) || defined(_WIN64)
#include <Windows.h>
#endif

namespace tightdb {

bool case_cmp(const char *constant_upper, const char *constant_lower, const char *source);
bool case_strstr(const char *constant_upper, const char *constant_lower, const char *source);
bool utf8case(const char *source, char *destination, int upper);
size_t case_prefix(const char *constant_upper, const char *constant_lower, const char *source);
bool utf8case_single(const char **source, char **destination, int upper);
size_t sequence_length(const char *lead);
size_t comparechars(const char *c1, const char *c2);
bool utf8case_single(const char *source, char *destination, int upper);

}

#endif
