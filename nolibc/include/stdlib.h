#ifndef _STDLIB_H
#define _STDLIB_H

#include <stddef.h>

void abort(void) __attribute__((noreturn));
void exit(int) __attribute__((noreturn));
void *malloc(size_t);
void free(void *);
void *calloc(size_t, size_t);
void *realloc(void *, size_t);

struct mallinfo {
  size_t arena;    /* non-mmapped space allocated from system */
  size_t ordblks;  /* number of free chunks */
  size_t smblks;   /* always 0 */
  size_t hblks;    /* always 0 */
  size_t hblkhd;   /* space in mmapped regions */
  size_t usmblks;  /* maximum total allocated space */
  size_t fsmblks;  /* always 0 */
  size_t uordblks; /* total allocated space */
  size_t fordblks; /* total free space */
  size_t keepcost; /* releasable (via malloc_trim) space */
};
struct mallinfo mallinfo(void);

char *getenv(const char *);
char *secure_getenv(const char *);
int system(const char *);
double strtod(const char *, char **);
long strtol(const char *, char **, int);

#endif
