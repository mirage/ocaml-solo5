#include <stdlib.h>
#include <stdio.h>

/*
 * These functions deliberately do not call printf() or malloc() in order to
 * abort as quickly as possible without triggering further errors.
 */

void _assert_fail(const char *file, const char *line, const char *e)
{
    puts(file);
    puts(":");
    puts(line);
    puts(": Assertion `");
    puts(e);
    puts("' failed\n");
    abort();
}
