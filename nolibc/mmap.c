#include <stdlib.h>
#include <stdio.h>

#include <sys/mman.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {

  /* man page for mmap says:
   * If addr is not NULL, then the kernel takes it as a hint about where to place
   * the mapping; [...] If another apping already exists there, the kernel picks
   * a new address that may or *may not* depend on the hint.
   */
  (void)addr;
  if (fildes != -1) {
    printf("mmap: file descriptor is unsupported.\n");
    abort();
  }
  (void)prot;
  (void)flags;
  (void)off;
  return malloc(len);
}
