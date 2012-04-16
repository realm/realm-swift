#ifndef UTILITIES_HEADER
#define UTILITIES_HEADER

#include <cstdlib>
#ifdef _MSC_VER
	#include "win32/types.h"
	#include "win32/stdint.h"
#endif

#if defined(_WIN32) || defined(__WIN32__) || defined(_WIN64)
	#define WINDOWS
#endif

#if (defined(__X86__) || defined(__i386__) || defined(i386) || defined(_M_IX86) || defined(__386__) || defined(__x86_64__) || defined(_M_X64))
	#define X86X64
#endif

#if defined(X86X64) && (defined(__GNUC__) || defined(__INTEL_COMPILER))
	#define tdb_likely(x) __builtin_expect (x, 1)
	#define tdb_unlikely(x) __builtin_expect (x, 0)
#else
	#define tdb_likely(x) (x)
	#define tdb_unlikely(x) (x)
#endif

#if defined _LP64 || defined __LP64__ || defined __64BIT__ || _ADDR64 || defined _WIN64 || defined __arch64__ || __WORDSIZE == 64 || (defined __sparc && defined __sparcv9) || defined __x86_64 || defined __amd64 || defined __x86_64__ || defined _M_X64 || defined _M_IA64 || defined __ia64 || defined __IA64__
	#define BITS64
#endif

typedef struct 
{
	unsigned long long remainder;
	unsigned long long remainder_len;
	unsigned long long b_val;
	unsigned long long a_val;
	unsigned long long result;
} checksum_t;

size_t TO_REF(int64_t v);
unsigned long long checksum(unsigned char *data, size_t len);
void checksum_rolling(unsigned char *data, size_t len, checksum_t *t);
void *round_up(void *p, size_t align);
void *round_down(void *p, size_t align);
size_t round_up(size_t p, size_t align);
size_t round_down(size_t p, size_t align);
void checksum_init(checksum_t *t);

#endif

