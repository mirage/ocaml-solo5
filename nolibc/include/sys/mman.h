#ifndef _MMAP_H
#define _MMAP_H

#include <stddef.h>
#include <sys/types.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off);

#define PROT_NONE 0
#define PROT_READ 1
#define PROT_WRITE 2

#define MAP_SHARED 0x01
#define MAP_PRIVATE 0x02
#define MAP_FIXED 0x10
#define MAP_ANONYMOUS 0x20
#define MAP_ANON MAP_ANONYMOUS

#define MAP_FAILED NULL

#define OCAML_SOLO5_PAGESIZE (1 << 12)

int munmap(void *addr, size_t len);

#endif
