#define ARCH_SIXTYFOUR
#define SIZEOF_INT 4
#define SIZEOF_LONG 4
#define SIZEOF_PTR 4
#define SIZEOF_SHORT 2
#define SIZEOF_LONGLONG 8
#define ARCH_INT64_TYPE long long
#define ARCH_UINT64_TYPE unsigned long long
#define ARCH_INT64_PRINTF_FORMAT "lld"
#undef ARCH_BIG_ENDIAN
#undef ARCH_ALIGN_DOUBLE
#undef ARCH_ALIGN_INT64
#define ASM_CFI_SUPPORTED
#define PROFINFO_WIDTH 26
#define INT64_LITERAL(s) s ## LL
