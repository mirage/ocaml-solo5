#include <unistd.h>

long sysconf(int x) {
  switch (x) {
  case _SC_PAGESIZE: /* _SC_PAGE_SIZE */
    return (1 << 12); /* TODO: How do we do better? */
  default:
    return -1;
  }
}
