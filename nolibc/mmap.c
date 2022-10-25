#include <stdlib.h>
#include <stdio.h>

#include <sys/mman.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {
  if (addr != NULL) {
    printf("mmap: non-null addr is unsupported.\n");
    abort();
  }
  if (fildes != -1) {
    printf("mmap: file descriptor is unsupported.\n");
    abort();
  }
  (void)prot;
  (void)flags;
  (void)off;
  return malloc(len);
}
