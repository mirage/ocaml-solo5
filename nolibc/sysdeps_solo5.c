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
    return solo5_console_write(s, l);
}

static FILE console = { .write = console_write };
FILE *stderr = &console;
FILE *stdout = &console;

ssize_t write(int fd, const void *buf, size_t count)
{
    if (fd == 1 || fd == 2)
	return solo5_console_write(buf, count);
    errno = ENOSYS;
    return -1;
}

void exit(int status)
{
    solo5_exit();
}

void abort(void)
{
    solo5_console_write("Aborted\n", 8);
    solo5_exit();
}

/*
 * System time.
 */
#define NSEC_PER_SEC 1000000000ULL

int gettimeofday(struct timeval *tv, struct timezone *tz)
{
    if (tv != NULL) {
	uint64_t now = solo5_clock_wall();
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


static struct solo5_info info;
/*
 * Called by dlmalloc to allocate or free memory.
 */
void *sbrk(intptr_t increment)
{
    static uint64_t heap_top;
    uint64_t prev, brk;

    if (!heap_top) {
        solo5_get_info(&info);
        heap_top = info.heap_start;
    }

    prev = brk = heap_top;

    /*
     * dlmalloc guarantees increment values less than half of size_t, so this
     * is safe from overflow.
     */
    brk += increment;
    if (brk >= info.heap_end || brk < info.heap_start)
        return (void *)-1;

    heap_top = brk;
    return (void *)prev;
}
