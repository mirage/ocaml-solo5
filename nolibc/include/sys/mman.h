#ifndef _MMAP_H
#define _MMAP_H

#include <stddef.h>

typedef int off_t;

extern void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off);

#define PROT_NONE 0
#define PROT_READ 1
#define PROT_WRITE 2

#define MAP_PRIVATE 0
#define MAP_ANONYMOUS 0
#define MAP_FIXED 0
#define MAP_SHARED 0

#define MAP_FAILED NULL

extern int munmap(void *addr, size_t len);

#endif
