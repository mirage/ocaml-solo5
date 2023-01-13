#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define STUB_ABORT(function) \
    int __unsup_##function(void) __asm__(#function) __attribute__((noreturn)); \
    int __unsup_##function(void) \
    { \
        printf("STUB: abort: %s() called\n", #function); \
	abort(); \
    }

/*
 * Warnings are deliberately disabled here to reduce unnecessary verbosity under
 * normal operation. To enable, replace "called = 1" with "called = 0" and
 * rebuild.
 */
#define STUB_WARN_ONCE(type, function, ret) \
    type __unsup_##function(void) __asm__(#function); \
    type __unsup_##function(void) \
    { \
        static int called = 1; \
        if (!called) {\
            printf("STUB: %s() called\n", #function); \
            called = 1; \
        } \
	errno = ENOSYS; \
	return ret; \
    }

#define STUB_IGNORE(type, function, ret) \
    type __unsup_##function(void) __asm__(#function); \
    type __unsup_##function(void) \
    { \
	errno = ENOSYS; \
	return ret; \
    }

/* stdio.h */
STUB_WARN_ONCE(int, fflush, 0);
STUB_ABORT(rename);
STUB_ABORT(sscanf); /* Used only for parsing OCAMLRUNPARAM, never called */
/*
 * The following stubs are not required by the OCaml runtime, but are
 * needed to build the freestanding version of GMP used by Mirage.
 */
STUB_WARN_ONCE(int, fread, 0);
STUB_WARN_ONCE(int, getc, EOF);
STUB_WARN_ONCE(int, ungetc, EOF);
STUB_WARN_ONCE(int, fwrite, 0);
STUB_WARN_ONCE(int, fputc, EOF);
STUB_WARN_ONCE(int, fputs, EOF);
STUB_WARN_ONCE(int, putc, EOF);
STUB_WARN_ONCE(int, ferror, 1);
STUB_WARN_ONCE(int, fopen, 1);
STUB_WARN_ONCE(int, fclose, 1);

/* stdlib.h */
STUB_WARN_ONCE(char *, getenv, NULL);
STUB_WARN_ONCE(char *, secure_getenv, NULL);
STUB_ABORT(system);

/* unistd.h */
STUB_WARN_ONCE(int, chdir, -1);
STUB_ABORT(close);
STUB_ABORT(getcwd);
STUB_WARN_ONCE(pid_t, getpid, 2);
STUB_WARN_ONCE(pid_t, getppid, 1);
STUB_IGNORE(int, isatty, 0);
STUB_IGNORE(off_t, lseek, -1);
STUB_ABORT(read);
STUB_IGNORE(int, readlink, -1);
STUB_ABORT(unlink);
STUB_ABORT(rmdir);
STUB_ABORT(ftruncate);

/* dirent.h */
STUB_WARN_ONCE(int, closedir, -1);
STUB_WARN_ONCE(void *, opendir, NULL);
STUB_WARN_ONCE(struct dirent *, readdir, NULL);

/* fcntl.h */
STUB_ABORT(fcntl);
STUB_WARN_ONCE(int, open, -1);

/* signal.h */
STUB_IGNORE(int, setjmp, 0);
STUB_ABORT(signal);
/*
 * The following stubs are not required by the OCaml runtime, but are
 * needed to build the freestanding version of GMP used by Mirage.
 */
STUB_ABORT(raise);

/* string.h */
STUB_ABORT(strerror);

/* sys/stat.h */
STUB_WARN_ONCE(int, stat, -1);
STUB_ABORT(mkdir);

/* pthread.h */
STUB_IGNORE(int, pthread_join, 0);
STUB_IGNORE(int, pthread_create, 0);
STUB_IGNORE(int, pthread_attr_init, 0);
STUB_ABORT(pthread_cleanup_push);
STUB_ABORT(pthread_cleanup_pop);

STUB_IGNORE(int, munmap, 0); /* TODO: Implement munmap correctly and avoid memory leaks */

int memory_order_release;
int memory_order_acquire;
int memory_order_relaxed;

STUB_ABORT(atomic_store_explicit);
STUB_ABORT(atomic_exchange);

/* above that line, for OCaml 5, those are only required (i guess) for the configure step */
STUB_IGNORE(int, pthread_mutex_lock, 0);
STUB_IGNORE(int, pthread_mutex_trylock, 0);
STUB_IGNORE(int, pthread_mutex_unlock, 0);
STUB_IGNORE(int, pthread_mutex_destroy, 0);
STUB_IGNORE(int, pthread_mutex_init, 0);

STUB_IGNORE(int, pthread_mutexattr_init, 0);
STUB_IGNORE(int, pthread_mutexattr_destroy, 0);
STUB_IGNORE(int, pthread_mutexattr_settype, 0);

STUB_IGNORE(int, pthread_sigmask, 0);

STUB_IGNORE(int, pthread_equal, 1);

STUB_IGNORE(int, pthread_condattr_init, 0);
/* TODO: Is there a memory leak in OCaml? Shouldn't there be a call to pthread_condattr_destroy? */

STUB_IGNORE(int, pthread_cond_init, 0);
STUB_ABORT(pthread_cond_destroy);
STUB_ABORT(pthread_cond_wait);
STUB_ABORT(pthread_cond_signal);
STUB_IGNORE(int, pthread_cond_broadcast, 0);
STUB_ABORT(pthread_self);
STUB_ABORT(pthread_detach);

STUB_ABORT(sigfillset);
STUB_ABORT(strerror_r);
