#include <string.h>
#include <stdint.h>
#include <limits.h>

#define ALIGN (sizeof(size_t))
#define ONES ((size_t)-1/UCHAR_MAX)
#define HIGHS (ONES * (UCHAR_MAX/2+1))
#define HASZERO(x) ((x)-ONES & ~(x) & HIGHS)

size_t strnlen(const char *s, size_t maxlen)
{
	const char *a = s;
	const size_t *w;
	size_t over = maxlen;
	for (; ((uintptr_t)s % ALIGN) && over; s++, over--) if (!*s) return s-a;
	for (w = (const void *)s; over>ALIGN && !HASZERO(*w); w++,over-=ALIGN);
	for (s = (const void *)w; *s && over; s++, over--);
	if (over) return s-a;
	else return maxlen;
}
