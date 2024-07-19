#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

#include <sys/mman.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {

  /* man page for mmap says:
   * If addr is NULL, then the kernel chooses the (page-aligned) address at
   * which to create the mapping; this is the most portable method of creating a
   * new mapping.
   *
   * For our purpose (Solo5 & OCaml), OCaml might use a NULL addr and force us to
   * use posix_memalign.
   * OCaml calls mmap with a non-null address and with the MAP_FIXED flag only
   * on already reserved memory to commit or decommit that memory block, ie to
   * set its protection to PROT_READ|PROT_WRITE or to PROT_NONE, in the
   * caml_mem_commit and caml_mem_decommit functions.
   * So we accept this particular case without allocating memory that would leak
   * since the OCaml code base simply ignores the returned value (as MAP_FIXED
   * enforces the returned value to be either addr or MAP_FAILED).
   *
   * The OCaml runtime uses [mmap()] only to allocate memory, so only
   * [fildes == 1] is handled.
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

  if (addr == NULL) {
    /* posix_memalign doesn't modify ptr on error: ptr will still be NULL and
     * so we will return MAP_FAILED with no need to check explicitly the value
     * returned by posix_memalign */
    posix_memalign(&ptr, OCAML_SOLO5_PAGESIZE, len);
  } else {
    if ((flags & MAP_FIXED) != 0) {
      /* Case where mmap is called to commit or decommit already reserved
       * memory. Since we ignore prot, we can simply let it go through */
      return addr;
    } else {
      /* We cannot handle this case */
      errno = EINVAL;
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

  free(addr);
  return 0;
}
