#ifndef _PTHREAD_H
#define _PTHREAD_H

#include <stddef.h>

typedef unsigned long int pthread_t;

int pthread_getaffinity_np ();

pthread_t pthread_self (void);

typedef int pthread_attr_t;

int pthread_create ();
int pthread_join ();
int pthread_attr_init ();
void pthread_cleanup_push ();
void pthread_cleanup_pop ();

typedef int pthread_mutex_t;
typedef int pthread_cond_t;

int pthread_mutex_lock ();
int pthread_mutex_trylock ();
int pthread_mutex_unlock ();

#define PTHREAD_MUTEX_INITIALIZER 0
#define PTHREAD_COND_INITIALIZER 0

int pthread_sigmask ();
int pthread_sigmask ();
int pthread_detach ();
int pthread_equal ();

typedef int pthread_mutexattr_t;

int pthread_mutexattr_init ();
int pthread_mutexattr_settype ();

#define PTHREAD_MUTEX_ERRORCHECK 0

int pthread_mutex_init ();
int pthread_mutexattr_destroy ();
int pthread_mutex_destroy ();

typedef int pthread_condattr_t;

int pthread_condattr_init ();
int pthread_cond_init ();

int pthread_cond_wait ();
int pthread_cond_broadcast ();
int pthread_cond_signal ();
int pthread_cond_destroy ();

#endif
