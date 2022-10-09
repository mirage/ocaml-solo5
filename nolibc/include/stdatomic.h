#ifndef _STDATOMIC_H
#define _STDATOMIC_H

#define atomic_load_explicit(x, mode) ( *x )
#define atomic_load(x) ( *x )

extern int memory_order_release;
extern int memory_order_acquire;
extern int memory_order_relaxed;
extern int memory_order_seq_cst;

#define atomic_fetch_add(X, Y) ({ __auto_type tmp = *X; *X = tmp + Y; tmp; })
#define atomic_fetch_add_explicit(X, Y, MOD) atomic_fetch_add(X, Y)

#define atomic_thread_fence(MO) do {} while (0)

typedef unsigned long long atomic_uint_fast64_t;

#define atomic_compare_exchange_strong(OBJ, EXPECTED, DESIRED) \
  ({ int ret = 0; \
     if (*OBJ == *EXPECTED) { \
       *OBJ = DESIRED; \
       ret = 1; \
     } \
     ret; \
  })

#define atomic_exchange(OBJ, DESIRED) \
  ({ __auto_type tmp = *OBJ; \
     *OBJ = DESIRED; \
     tmp; \
  })

#define atomic_store(OBJ, DESIRED) do { *OBJ = DESIRED; } while(0)
#define atomic_store_explicit(OBJ, DESIRED, ORDER) atomic_store(OBJ, DESIRED)

void atomic_fetch_or();

#endif
