#include <string.h>
#include <unistd.h>

extern void solo5_console_write(const char *, size_t);

int puts(const char *s)
{
    size_t len = strlen(s);
    solo5_console_write(s, len);
    return (len);
}

int putchar(int chr)
{
    solo5_console_write((char *) &chr, 1);
    return (1);
}
