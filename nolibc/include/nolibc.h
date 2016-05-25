#ifndef NOLIBC_H_INCLUDED
#define NOLIBC_H_INCLUDED

#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>

/* stdlib.h */

void *malloc(size_t);
void free(void *);
void *calloc(size_t, size_t);
void *realloc(void *, size_t);
char *getenv(const char *);
int system(const char *);
double strtod(const char *, char **);

/* unistd.h */
int chdir(const char *);
int close(int);
void exit(int) __attribute__((noreturn));
char *getcwd(char *, size_t);
typedef int pid_t;
pid_t getpid(void);
pid_t getppid(void);
typedef int off_t;
off_t lseek(int, off_t, int); /* SEEK_ */
typedef int ssize_t;
ssize_t read(int, void *, size_t);
ssize_t write(int, const void *, size_t);
ssize_t readlink(const char *, char *, size_t);
int unlink(const char *);

/* sys/time.h */
typedef long time_t;
typedef long suseconds_t;
struct timeval {
    time_t tv_sec;
    suseconds_t tv_usec;
};
struct timezone {
    int tz_minuteswest;
    int tz_dsttime;
};
int gettimeofday(struct timeval *tv, struct timezone *tz);

/* dirent.h */
typedef int DIR;
int closedir(DIR *);
DIR *opendir(const char *);
struct dirent {
    char *d_name;
};
struct dirent *readdir(DIR *);

/* errno.h */
extern int errno;
#define EBADF 1
#define ERANGE 2
#define ENOSYS 3
#define EOVERFLOW 4 /* printf */

/* fcntl.h */
int fcntl(int, int, ...);
int open(const char *, int, ...);
#define O_RDONLY (1<<0)
#define O_WRONLY (1<<1)
#define O_APPEND (1<<2)
#define O_CREAT (1<<3)
#define O_TRUNC (1<<4)
#define O_EXCL (1<<5)

/* stdio.h */
struct _FILE;
typedef struct _FILE {
    size_t (*write)(struct _FILE *f, const char *, size_t);
    char *wpos;
    char *wend;
} FILE;
int fflush(FILE *);
int fprintf(FILE *, const char *, ...);
int printf(const char *, ...);
int rename(const char *, const char *);
extern FILE *stdout;
extern FILE *stderr;
int sscanf(const char *, const char *, ...);
int snprintf(char *, size_t, const char *, ...);
int vfprintf(FILE *, const char *, va_list);
int vsnprintf(char *, size_t, const char *, va_list);

/* signal.h */
typedef int sigjmp_buf;
typedef int sigset_t;
struct sigaction {
    void (*sa_handler)(int);
    sigset_t sa_mask;
    int sa_flags;
};
#define SIG_DFL NULL
#define SIG_IGN NULL
int sigaction(int, const struct sigaction *, struct sigaction *);
int sigsetjmp(sigjmp_buf, int);
int sigaddset(sigset_t *set, int);
int sigdelset(sigset_t *set, int);
int sigemptyset(sigset_t *set);
#define SIG_BLOCK 0
#define SIG_SETMASK 0
int sigprocmask(int, const sigset_t *, sigset_t *);

/* string.h */
int memcmp(const void *, const void *, size_t);
void *memchr(const void *, int, size_t); /* printf */
void *memcpy(void *, const void *, size_t);
void *memmove(void *, const void *, size_t);
void *memset(void *, int, size_t);
int strcmp(const char *, const char *);
size_t strlen(const char *);
char *strerror(int);

/* limits.h */
#define INT_MAX  0x7fffffff
#define INT_MIN  (-1-0x7fffffff)
#if defined(__x86_64__)
#define LONG_MAX  0x7fffffffffffffffL
#define LLONG_MAX  0x7fffffffffffffffLL
#else
#error Unsupported architecture
#endif
#define LONG_MIN (-LONG_MAX-1)
#define LLONG_MIN (-LLONG_MAX-1)
#define ULONG_MAX (2UL*LONG_MAX+1) /* printf */
#define NL_ARGMAX 9 /* printf */
#define UCHAR_MAX 255 /* memchr */

/* ctype.h */
int isdigit(int); /* printf */
int isprint(int);

/* sys/stat.h */
struct stat {
    int st_mode;
};
#define S_IFDIR 0
#define S_IFMT 0
#define S_IFREG 0
#define S_ISREG(x) (0)
int stat(const char *, struct stat *);

/* sys/times.h */
typedef int clock_t;
struct tms {
    clock_t tms_utime;
    clock_t tms_stime;
    clock_t tms_cutime;
    clock_t tms_cstime;
};
clock_t times(struct tms *buf);

/* sys/cdefs.h */
#define _SYS_CDEFS_H /* Openlibm uses this to detect if cdefs.h was included */
#define __BEGIN_DECLS
#define __END_DECLS

/* endian.h */
#define __LITTLE_ENDIAN 1234
#define __BIG_ENDIAN 4321
#if defined(__x86_64__)
#define __BYTE_ORDER __LITTLE_ENDIAN
#else
#error Unsupported architecture
#endif

/* assert.h */
#define assert(x) (void)0

#endif
