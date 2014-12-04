#ifndef TIGHTDB_NMMINTRIN_H
#define TIGHTDB_NMMINTRIN_H

/*
    We must support runtime detection of CPU support of SSE when distributing TightDB as a closed source library.

    This is a problem on gcc and llvm: To use SSE intrinsics we need to pass -msse on the command line (to get offered
    __builtin_ accessors used by intrinsics functions). However, the -msse flag allows gcc to emit SSE instructions
    in its code generation/optimization. This is unwanted because the binary would crash on non-SSE CPUs.

    Since there exists no flag in gcc that enables intrinsics but probits SSE in code generation, we define our
    own intrinsics to be assembled by the back end assembler and omit passing -msse to gcc.
*/

#ifndef _MSC_VER

#ifdef TIGHTDB_COMPILER_SSE
    #include <emmintrin.h> // SSE2 (using __m128i)
#endif

#ifdef TIGHTDB_COMPILER_AVX
typedef float __m256 __attribute__((__vector_size__(32), __may_alias__));
typedef double __m256d __attribute__((__vector_size__(32), __may_alias__));

const int _CMP_EQ_OQ = 0x00; // Equal (ordered, non-signaling)
const int _CMP_NEQ_OQ = 0x0c; // Not-equal (ordered, non-signaling)
const int _CMP_LT_OQ = 0x11; // Less-than (ordered, non-signaling)
const int _CMP_LE_OQ = 0x12; // Less-than-or-equal (ordered, non-signaling)
const int _CMP_GE_OQ = 0x1d; // Greater-than-or-equal (ordered, non-signaling)
const int _CMP_GT_OQ = 0x1e; // Greater-than (ordered, non-signaling)


template <int op> static int movemask_cmp_ps(__m256* y1, __m256* y2)
{
    int ret;
    __asm__("vmovaps %0, %%ymm0"                    :                   : "m"(*y1)                      : "%xmm0"   );
    __asm__("vmovaps %0, %%ymm1"                    :                   : "m"(*y2)                      : "%xmm1"   );
    __asm__("vcmpps %0, %%ymm0, %%ymm1, %%ymm0"     :                   : "I"(op)                       : "%xmm0"   );
    __asm__("vmovmskps %%ymm0, %0"                  : "=r"(ret)         :                               :           );
    return ret;
}

template <int op> static inline int movemask_cmp_pd(__m256d* y1, __m256d* y2)
{
    int ret;
    __asm__("vmovapd %0, %%ymm0"                    :                   : "m"(*y1)                      : "%xmm0"   );
    __asm__("vmovapd %0, %%ymm1"                    :                   : "m"(*y2)                      : "%xmm1"   );
    __asm__("vcmppd %0, %%ymm0, %%ymm1, %%ymm0"     :                   : "I"(op)                       : "%xmm0"   );
    __asm__("vmovmskpd %%ymm0, %0"                  : "=r"(ret)         :                               :           );
    return ret;
}



static inline int movemask_cmp_ps(__m256* y1, __m256* y2, int op)
{
    // todo, use constexpr;
    if (op == _CMP_EQ_OQ)
        return movemask_cmp_ps<_CMP_NEQ_OQ>(y1, y2);
    else if (op == _CMP_NEQ_OQ)
        return movemask_cmp_ps<_CMP_NEQ_OQ>(y1, y2);
    else if (op == _CMP_LT_OQ)
        return movemask_cmp_ps<_CMP_LT_OQ>(y1, y2);
    else if (op == _CMP_LE_OQ)
        return movemask_cmp_ps<_CMP_LE_OQ>(y1, y2);
    else if (op == _CMP_GE_OQ)
        return movemask_cmp_ps<_CMP_GE_OQ>(y1, y2);
    else if (op == _CMP_GT_OQ)
        return movemask_cmp_ps<_CMP_GT_OQ>(y1, y2);

    TIGHTDB_ASSERT(false);
    return 0;
}

static inline int movemask_cmp_pd(__m256d* y1, __m256d* y2, int op)
{
    // todo, use constexpr;
    if (op == _CMP_EQ_OQ)
        return movemask_cmp_pd<_CMP_NEQ_OQ>(y1, y2);
    else if (op == _CMP_NEQ_OQ)
        return movemask_cmp_pd<_CMP_NEQ_OQ>(y1, y2);
    else if (op == _CMP_LT_OQ)
        return movemask_cmp_pd<_CMP_LT_OQ>(y1, y2);
    else if (op == _CMP_LE_OQ)
        return movemask_cmp_pd<_CMP_LE_OQ>(y1, y2);
    else if (op == _CMP_GE_OQ)
        return movemask_cmp_pd<_CMP_GE_OQ>(y1, y2);
    else if (op == _CMP_GT_OQ)
        return movemask_cmp_pd<_CMP_GT_OQ>(y1, y2);

    TIGHTDB_ASSERT(false);
    return 0;
}


#endif

// Instructions introduced by SSE 3 and 4.2
static inline __m128i _mm_cmpgt_epi64(__m128i xmm1, __m128i xmm2)
{
    __asm__("pcmpgtq %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i _mm_cmpeq_epi64(__m128i xmm1, __m128i xmm2)
{
    __asm__("pcmpeqq %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_min_epi8(__m128i xmm1, __m128i xmm2)
{
    __asm__("pminsb %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_max_epi8(__m128i xmm1, __m128i xmm2)
{
    __asm__("pmaxsb %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_max_epi32(__m128i xmm1, __m128i xmm2)
{
    __asm__("pmaxsd %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_min_epi32(__m128i xmm1, __m128i xmm2)
{
    __asm__("pminsd %1, %0" : "+x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_cvtepi8_epi16(__m128i xmm2)
{
    __m128i xmm1;
    __asm__("pmovsxbw %1, %0" : "=x" (xmm1) : "xm" (xmm2) : "xmm1");
    return xmm1;
}
static inline __m128i __attribute__((always_inline)) _mm_cvtepi16_epi32(__m128i xmm2)
{
    __m128i xmm1;
    asm("pmovsxwd %1, %0" : "=x" (xmm1) : "xm" (xmm2));
    return xmm1;
}

static inline __m128i __attribute__((always_inline)) _mm_cvtepi32_epi64(__m128i xmm2)
{
    __m128i xmm1;
    __asm__("pmovsxdq %1, %0" : "=x" (xmm1) : "xm" (xmm2));
    return xmm1;
}
#endif
#endif
