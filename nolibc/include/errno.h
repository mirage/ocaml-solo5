#ifndef _ERRNO_H
#define _ERRNO_H

extern int errno;
#define EBADF     9     /* Bad file number */
#define ENOENT    2     /* No such file or directory */
#define ENOMEM    12    /* Out of memory */
#define EBUSY     16    /* Device or resource busy */
#define EINVAL    22    /* Invalid argument */
#define EMFILE    24    /* Too many open files */
#define ERANGE    34    /* Math result not representable */
#define ENOSYS    38    /* Invalid system call number */
#define EOVERFLOW 75    /* Value too large for defined data type */

#endif
