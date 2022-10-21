#ifndef _PTHREAD_H
#define _PTHREAD_H

#include <stddef.h>
#include <signal.h>

typedef unsigned long int pthread_t;
typedef int cpu_set_t;

int pthread_getaffinity_np(pthread_t, size_t, cpu_set_t *);

pthread_t pthread_self(void);

typedef int pthread_attr_t;

int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *);
int pthread_join(pthread_t, void **);
int pthread_attr_init(pthread_attr_t *);
void pthread_cleanup_push(void (*)(void *), void *);
void pthread_cleanup_pop(int);

typedef int pthread_mutex_t;
typedef int pthread_cond_t;

typedef int pthread_mutex_t;

int pthread_mutex_lock(pthread_mutex_t *);
int pthread_mutex_trylock(pthread_mutex_t *);
int pthread_mutex_unlock(pthread_mutex_t *);

#define PTHREAD_MUTEX_INITIALIZER 0
#define PTHREAD_COND_INITIALIZER 0

int pthread_sigmask(int, const sigset_t *, sigset_t *);
int pthread_detach(pthread_t);
int pthread_equal(pthread_t, pthread_t);

typedef int pthread_mutexattr_t;

int pthread_mutexattr_init(pthread_mutexattr_t *);
int pthread_mutexattr_settype(pthread_mutexattr_t *, int);

#define PTHREAD_MUTEX_ERRORCHECK 0

int pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *);
int pthread_mutexattr_destroy(pthread_mutexattr_t *);
int pthread_mutex_destroy(pthread_mutex_t *);

typedef int pthread_condattr_t;

int pthread_condattr_init(pthread_condattr_t *);
int pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *);

int pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *);
int pthread_cond_broadcast(pthread_cond_t *);
int pthread_cond_signal(pthread_cond_t *);
int pthread_cond_destroy(pthread_cond_t *);

#endif
