#include <stdlib.h>
#include <stdio.h>

#include <sys/mman.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {

  /* man page for mmap says:
   * If addr is not NULL, then the kernel takes it as a hint about where to place
   * the mapping; [...] If another apping already exists there, the kernel picks
   * a new address that may or *may not* depend on the hint.
   *
   * XXX(dinosaure): for our purpose (Solo5 & OCaml), OCaml does not require a
   * specific (aligned) address from [mmap]. We can use [malloc()] instead of.
   * The OCaml usage of [mmap()] is only to allocate some spaces, only [fildes
   * == -1] is handled so.
   */
  (void)addr;
  (void)prot;
  if (fildes != -1) {
    printf("mmap: file descriptor is unsupported.\n");
    abort();
  }
  if (!(flags & MAP_ANONYMOUS) || off != 0) {
    printf("mmap: only MAP_ANONYMOUS (and offset is 0) is supported.\n");
    abort();
  }

  void *ptr = NULL;
  posix_memalign(&ptr, OCAML_SOLO5_PAGESIZE, len);
  /* XXX(palainp): Solo5 returns -1 and set errno on error, and it does not
   * modify ptr, however both are not standardized. We can return NULL to the
   * caller on error and do not check the returned value here. */
  return ptr;
}
