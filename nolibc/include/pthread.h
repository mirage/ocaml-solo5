#ifndef _PTHREAD_H
#define _PTHREAD_H

#include <stddef.h>

typedef unsigned long int pthread_t;

extern int pthread_getaffinity_np ();

extern pthread_t pthread_self (void);

typedef int pthread_attr_t;

extern int pthread_create ();
extern int pthread_join ();
extern int pthread_attr_init ();
extern void pthread_cleanup_push ();
extern void pthread_cleanup_pop ();

typedef int pthread_mutex_t;
typedef int pthread_cond_t;

extern int pthread_mutex_lock ();
extern int pthread_mutex_trylock ();
extern int pthread_mutex_unlock ();

#define PTHREAD_MUTEX_INITIALIZER 0
#define PTHREAD_COND_INITIALIZER 0

extern int pthread_sigmask ();
extern int pthread_sigmask ();
extern int pthread_detach ();
extern int pthread_equal ();

typedef int pthread_mutexattr_t;

extern int pthread_mutexattr_init ();
extern int pthread_mutexattr_settype ();

#define PTHREAD_MUTEX_ERRORCHECK 0

extern int pthread_mutex_init ();
extern int pthread_mutexattr_destroy ();
extern int pthread_mutex_destroy ();

typedef int pthread_condattr_t;

extern int pthread_condattr_init ();
extern int pthread_cond_init ();

extern int pthread_cond_wait ();
extern int pthread_cond_broadcast ();
extern int pthread_cond_signal ();
extern int pthread_cond_destroy ();

#endif
