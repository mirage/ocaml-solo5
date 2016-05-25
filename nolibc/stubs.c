#include <nolibc.h>

#define STUB_ABORT(function) \
    int __unsup_##function(void) __asm__(#function) __attribute__((noreturn)); \
    int __unsup_##function(void) \
    { \
        printf("STUB: abort: %s() called\n", #function); \
	exit(1); \
    }

#define STUB_WARN_ONCE(type, function, ret) \
    type __unsup_##function(void) __asm__(#function); \
    type __unsup_##function(void) \
    { \
        static int called = 0; \
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
STUB_ABORT(sscanf); /* Used only for parsing OCAMLRUNPARAM, never called */

/* stdlib.h */
STUB_WARN_ONCE(char *, getenv, NULL);
STUB_ABORT(system);

/* unistd.h */
STUB_WARN_ONCE(int, chdir, -1);
STUB_ABORT(close);
STUB_ABORT(getcwd);
STUB_WARN_ONCE(pid_t, getpid, 2);
STUB_WARN_ONCE(pid_t, getppid, 1);
STUB_IGNORE(off_t, lseek, -1);
STUB_ABORT(read);
STUB_IGNORE(int, readlink, -1);
STUB_ABORT(unlink);

/* dirent.h */
STUB_WARN_ONCE(int, closedir, -1);
STUB_WARN_ONCE(void *, opendir, NULL);
STUB_WARN_ONCE(struct dirent *, readdir, NULL);

/* fcntl.h */
STUB_ABORT(fcntl);
STUB_WARN_ONCE(int, open, -1);

/* stdio.h */
STUB_ABORT(rename);

/* signal.h */
STUB_IGNORE(int, sigaction, -1);
STUB_IGNORE(int, sigsetjmp, 0);
STUB_IGNORE(int, sigaddset, -1);
STUB_IGNORE(int, sigdelset, -1);
STUB_IGNORE(int, sigemptyset, -1);
STUB_IGNORE(int, sigprocmask, -1);

/* string.h */
STUB_ABORT(strerror);

/* sys/stat.h */
STUB_WARN_ONCE(int, stat, -1);
