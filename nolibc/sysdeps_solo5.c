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

static uintptr_t tls_main;

/*
 * To be called by Mirage/Solo5 before calling caml_startup().
 *
 * XXX: There is intentionally no public prototype for this function. There
 * should really be a caml_solo5_startup(), but I'm lazy and don't have
 * a proper place to put it in the build system right now.
 */
extern void mm_init(uint64_t start_addr, uint64_t end_addr);
#define PAGE_SIZE 4096

void _nolibc_init(uintptr_t heap_start, size_t heap_size)
{
    /*
     * We can realistically run with less than 8MB of memory
     */
    if (heap_size < 0x800000) {
        solo5_console_write("Not enough memory\n", 18);
        abort();
    }

    mm_init(heap_start, heap_start + heap_size);

    // init thread local storage for our unique domain
    tls_main = (uintptr_t)calloc(solo5_tls_size(), sizeof(uint8_t));
    if (tls_main == (uintptr_t)NULL) {
        solo5_console_write("TLS alloc failed\n", 17);
        abort();
    }
    if (solo5_tls_init(tls_main) != SOLO5_R_OK) {
        solo5_console_write("TLS init failed\n", 16);
        abort();
    }
    if (solo5_set_tls_base(solo5_tls_tp_offset(tls_main)) != SOLO5_R_OK) {
        solo5_console_write("TLS set failed\n", 15);
        abort();
    }
}
