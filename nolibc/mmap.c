#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

#include <sys/mman.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {

  /* man page for mmap says:
   * If addr is NULL, then the kernel chooses the (page-aligned) address  at
   * which to create the mapping; this is the most portable method of creat‐
   * ing a new mapping. If addr is not NULL, then the kernel takes it as a hint
   * about where to place the mapping; [...] If another apping already exists
   * there, the kernel picks a new address that may or *may not* depend on the hint.
   *
   * For our purpose (Solo5 & OCaml), OCaml might use a NULL addr and force us to
   * use posix_memalign. If addr is not NULL we might use [malloc()] instead of.
   * XXX(palainp): Does it worth to have a test on addr here?
   *
   * The OCaml usage of [mmap()] is only to allocate some spaces, only [fildes
   * == -1] is handled so.
   */
  (void)addr; // unused argument
  (void)prot; // unused argument

  if (fildes != -1) {
    printf("mmap: file descriptor is unsupported.\n");
    abort();
  }
  if (!(flags & MAP_ANONYMOUS) || off != 0) {
    printf("mmap: only MAP_ANONYMOUS (and offset is 0) is supported.\n");
    abort();
  }

  void *ptr = NULL;
  int ret = posix_memalign(&ptr, OCAML_SOLO5_PAGESIZE, len);
  if (ret == -1) {
    /* Solo5 returns -1 and set errno on error, just return MAP_FAILED. */
    return (void*)-1; // MAP_FAILED
  } else {
    return ptr;
  }
}

int munmap(void *addr, size_t length)
{
  (void)length; // unused argument

  /* man page for munmap says:
   * The address addr must be a multiple of the page size (but length need not be).
   */
  if ((uintptr_t)addr & OCAML_SOLO5_PAGESIZE != 0) {
    errno = EINVAL;
    return -1;
  }

  free(addr);
  return 0;
}
