#ifndef _STDATOMIC_H
#define _STDATOMIC_H

extern void atomic_store_explicit();

// TODO
#define atomic_exchange(ptr, val) ({ *ptr = val; *ptr; })

#define atomic_load_explicit(x, mode) ( *x )
#define atomic_load(x) ( *x )

extern int memory_order_release;
extern int memory_order_acquire;
extern int memory_order_relaxed;
extern int memory_order_seq_cst;

int atomic_fetch_add ();

#define atomic_thread_fence(MO) do {} while (0)

typedef unsigned long long atomic_uint_fast64_t;

int atomic_fetch_add_explicit ();
int atomic_compare_exchange_strong ();
void atomic_store();

void atomic_fetch_or();

#endif
