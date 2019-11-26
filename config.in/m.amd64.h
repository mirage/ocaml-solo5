#define ARCH_SIXTYFOUR
#define SIZEOF_INT 4
#define SIZEOF_LONG 8
#define SIZEOF_PTR 8
#define SIZEOF_SHORT 2
#if defined(__OpenBSD__)
    #define ARCH_INT64_TYPE long long
    #define ARCH_UINT64_TYPE unsigned long long
#else
    #define ARCH_INT64_TYPE long
    #define ARCH_UINT64_TYPE unsigned long
#endif
#define ARCH_INT64_PRINTF_FORMAT "l"
#undef ARCH_BIG_ENDIAN
#undef ARCH_ALIGN_DOUBLE
#undef ARCH_ALIGN_INT64
#undef NONSTANDARD_DIV_MOD
#define PROFINFO_WIDTH 26
#define INT64_LITERAL(s) s ## LL
