#ifndef _ERRNO_H
#define _ERRNO_H

extern int errno;
#define EBADF 1
#define ERANGE 2
#define ENOSYS 3
#define EOVERFLOW 4
#define ENOENT 5
#define EINVAL 6
#define ENOMEM 7
#define EMFILE 8
#define EBUSY 9
/* TODO(dinosaure): we probably should follow the Cosmopolitan
 * project about these constants and use values where we have
 * an {unix,bsd} consensus. */

#endif
