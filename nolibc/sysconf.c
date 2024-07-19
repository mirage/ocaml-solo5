#include <unistd.h>
#include <sys/mman.h>

long sysconf(int x) {
  switch (x) {
  case _SC_PAGESIZE: /* _SC_PAGE_SIZE */
    return OCAML_SOLO5_PAGESIZE;
  default:
    return -1;
  }
}
