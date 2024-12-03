#ifndef _ASSERT_H
#define _ASSERT_H

extern void _assert_fail(const char *, const char *, const char *)
    __attribute__((noreturn));

#define _ASSERT_STR_EXPAND(y) #y
#define _ASSERT_STR(x)        _ASSERT_STR_EXPAND(x)

#define assert(e)                                              \
    do {                                                       \
        if (!(e))                                              \
            _assert_fail(__FILE__, _ASSERT_STR(__LINE__), #e); \
    } while (0)

#endif

#ifndef static_assert
# define static_assert _Static_assert
#endif
