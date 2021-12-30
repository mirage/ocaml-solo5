#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <sys/times.h>
#include <unistd.h>

#include <solo5.h>

/*
 * Global errno lives in this module.
 */
int errno;

/*
 * Standard output and error "streams".
 */
static size_t console_write(FILE *f __attribute__((unused)), const char *s,
        size_t l)
{
    solo5_console_write(s, l);
    return l;
}

static FILE console = { .write = console_write };
FILE *stderr = &console;
FILE *stdout = &console;

ssize_t write(int fd, const void *buf, size_t count)
{
    if (fd == 1 || fd == 2) {
        solo5_console_write(buf, count);
        return count;
    }
    errno = ENOSYS;
    return -1;
}

void exit(int status)
{
    solo5_exit(status);
}

void abort(void)
{
    solo5_console_write("Aborted\n", 8);
    solo5_abort();
}

/*
 * System time.
 */
#define NSEC_PER_SEC 1000000000ULL

int gettimeofday(struct timeval *tv, struct timezone *tz)
{
    if (tv != NULL) {
        solo5_time_t now = solo5_clock_wall();
        tv->tv_sec = now / NSEC_PER_SEC;
        tv->tv_usec = (now % NSEC_PER_SEC) / 1000ULL;
    }
    if (tz != NULL) {
        memset(tz, 0, sizeof(*tz));
    }
    return 0;
}

clock_t times(struct tms *buf)
{
    memset(buf, 0, sizeof(*buf));
    return (clock_t)solo5_clock_monotonic();
}

static uintptr_t sbrk_start;
static uintptr_t sbrk_end;
static uintptr_t sbrk_cur;
static uintptr_t sbrk_guard_size;

/*
 * To be called by Mirage/Solo5 before calling caml_startup().
 *
 * XXX: There is intentionally no public prototype for this function. There
 * should really be a caml_freestanding_startup(), but I'm lazy and don't have
 * a proper place to put it in the build system right now.
 */
void _nolibc_init(uintptr_t heap_start, size_t heap_size)
{
    /*
     * If we have <1MB of heap available at init time then don't let the heap
     * grow to within (heap_size / 2) of the stack, otherwise don't let it
     * grow to within 1MB of the stack.
     */
    sbrk_guard_size = (heap_size >= 0x100000) ?
        0x100000 : (heap_size / 2);

    sbrk_start = sbrk_cur = heap_start;
    sbrk_end = heap_start + heap_size;
}

/*
 * Called by dlmalloc to allocate or free memory.
 */
void *sbrk(intptr_t increment)
{
    uintptr_t prev, brk;
    uintptr_t max = (uintptr_t)&prev - sbrk_guard_size;
    prev = brk = sbrk_cur;

    /*
     * dlmalloc guarantees increment values less than half of size_t, so this
     * is safe from overflow.
     */
    brk += increment;
    if (brk >= max || brk >= sbrk_end || brk < sbrk_start)
        return (void *)-1;

    sbrk_cur = brk;
    return (void *)prev;
}

/* solo5_app_main and __solo5_mft1_note as weak symbols to allow linking
 * executables, as done by OCaml's configure script to produce executables
 * in the ../ocaml directory of this repository.
 *
 * The weak attribute is required (and supported on gcc and clang) to have
 * mirage (mirage-solo5/mirage-xen) overwrite this symbol with a strong symbol
 * which executes the application.
 */
#pragma weak solo5_app_main
int solo5_app_main (const struct solo5_start_info *info) {
  const char* msg =
    "The weak solo5_app_main symbol from nolibc in ocaml-freestanding was "
    "called, which should be overwritten by mirage-solo5/mirage-xen!\n";
  solo5_console_write(msg, 134);
  return -1;
}

#pragma weak __solo5_mft1_note
#include <mft_abi.h>
const struct mft1_note __solo5_mft1_note;

/*
 * dlmalloc configuration:
 */

/*
 * DEBUG not defined and assertions enabled corresponds to the recommended
 * configuration as our assert() does not call malloc().  (see documentation in
 * dlmalloc.i). If you need to debug dlmalloc on Solo5 then define DEBUG to `1'
 * here.
 */
#include <assert.h>
#define ABORT_ON_ASSERT_FAILURE 0

#undef WIN32
#define HAVE_MMAP 0
#define HAVE_MREMAP 0
#define MMAP_CLEARS 0
#define NO_MALLOC_STATS 1
#define LACKS_FCNTL_H
#define LACKS_SYS_PARAM_H
#define LACKS_SYS_MMAN_H
#define LACKS_STRINGS_H
#define LACKS_SYS_TYPES_H
#define LACKS_SCHED_H
#define LACKS_TIME_H
#define MALLOC_FAILURE_ACTION
#define USE_LOCKS 0
#define STRUCT_MALLINFO_DECLARED 1
#define FOOTERS 1

/* disable null-pointer-arithmetic warning on clang */
#if defined(__clang__) && __clang_major__ >= 6
#pragma clang diagnostic ignored "-Wnull-pointer-arithmetic"
#endif

/* inline the dlmalloc implementation into this module */
#include "dlmalloc.i"

/*
 * When adding new functions to this module, add them BEFORE the "dlmalloc
 * configuration" comment above, not here.
 */
