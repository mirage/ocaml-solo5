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
   * use posix_memalign. If addr is not NULL we can use [malloc()] instead of.
   *
   * The OCaml usage of [mmap()] is only to allocate some spaces, only [fildes
   * == -1] is handled so.
   */
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
  /* XXX(palainp): Does it worth to have a test on addr here? */
  if (addr == NULL) {
    /* Solo5 may returns -1 and set errno on error, just return MAP_FAILED.
       It doesn't modify ptr on error: ptr will still be NULL
     */
    posix_memalign(&ptr, OCAML_SOLO5_PAGESIZE, len);
    //printf("DEBUG: mmap: posix_memalign for %lu @%p.\n", len, ptr);
  } else {
    ptr = malloc(len);
    //printf("DEBUG: mmap: malloc for %lu @%p.\n", len, ptr);
    if (ptr == NULL) {
      errno = ENOMEM;
    }
  }

  if (ptr == NULL) {
    return MAP_FAILED;
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

  //printf("DEBUG: munmap: free for %lu @%p.\n", length, addr);

  // FIXME! palainp: Calling free below leads to a PF in the free function
  // An example run:
  //   Ocaml calls mmap for a 2101248B domain stack (513 pages)
  //   Immediatly it releases the last page with munmap, and sadly this page
  //     hasn't been allocated with malloc => free will hangs the unikernel
  // Other runs:
  //   Ocaml calls mmap for 2101248B (136 pages)
  //   Immediatly after it calls munmap on the first 7 pages and the last page
  //     => calling free with make the whole area unaviable and calling free on
  //     the last page will behave like the previous example
  // In other words do  we need to add a complete page tracker here (and
  //   configure dlmalloc for using mmap)?

  // free(addr);
  return 0;
}
