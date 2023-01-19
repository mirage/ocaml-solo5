#ifndef _STDATOMIC_H
#define _STDATOMIC_H

#ifndef __has_builtin         // Optional of course.
  #define __has_builtin(x) 0  // Compatibility with non-clang compilers.
#endif

#define atomic_load_explicit(x, mode) ( *x )
#define atomic_load(x) ( *x )

extern int memory_order_release;
extern int memory_order_acquire;
extern int memory_order_relaxed;
extern int memory_order_seq_cst;

#if __has_builtin(__c11_atomic_fetch_add)
#define atomic_fetch_add(OBJ, ARG) __c11_atomic_fetch_add(OBJ, ARG, __ATOMIC_SEQ_CST)
#else
#define atomic_fetch_add(X, Y) ({ __auto_type tmp = *X; *X = tmp + Y; tmp; })
#endif

#define atomic_fetch_add_explicit(X, Y, MOD) atomic_fetch_add(X, Y)

#define atomic_thread_fence(MO) do {} while (0)

typedef unsigned long long atomic_uint_fast64_t;

#if __has_builtin(__c11_atomic_compare_exchange_strong)
#define atomic_compare_exchange_strong(OBJ, EXPECTED, DESIRED) __c11_atomic_compare_exchange_strong(OBJ, EXPECTED, DESIRED, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)
#else
#define atomic_compare_exchange_strong(OBJ, EXPECTED, DESIRED) \
  ({ int ret = 0; \
     if (*OBJ == *EXPECTED) { \
       *OBJ = DESIRED; \
       ret = 1; \
     } \
     ret; \
  })
#endif

#if __has_builtin(__c11_atomic_exchange)
#define atomic_exchange(OBJ, DESIRED) __c11_atomic_exchange(OBJ, DESIRED, __ATOMIC_SEQ_CST)
#else
#define atomic_exchange(OBJ, DESIRED) \
  ({ __auto_type tmp = *OBJ; \
     *OBJ = DESIRED; \
     tmp; \
  })
#endif

#define atomic_store(OBJ, DESIRED) do { *OBJ = DESIRED; } while(0)
#define atomic_store_explicit(OBJ, DESIRED, ORDER) atomic_store(OBJ, DESIRED)

#if __has_builtin(__c11_atomic_fetch_or)
#define atomic_fetch_or(OBJ, ARG) __c11_atomic_fetch_or(OBJ, ARG, __ATOMIC_SEQ_CST)
#else
#define atomic_fetch_or(OBJ, ARG) \
  ({ __auto_type tmp = *OBJ; \
     *OBJ = *OBJ | ARG; \
     tmp; \
  })
#endif

#endif
