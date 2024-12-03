#include <errno.h>
#include <stdio.h>
#include <string.h>

extern const char *const sys_errlist[];

int strerror_r(int num, char *buf, size_t buflen)
{
	if (num < 0 || num >= NB_ERRORS) {
		errno = EINVAL;
		return EINVAL;
	}
	if (snprintf(buf, buflen, "%s", sys_errlist[num]) >= (int)buflen) {
		errno = ERANGE;
		return ERANGE;
	}

	return 0;
}
