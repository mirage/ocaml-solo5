#ifndef _ERRNO_H
#define _ERRNO_H

extern int errno;

/* The following values are taken from:
 * https://github.com/openbsd/src/blob/master/sys/sys/errno.h
 */
#define ENOENT       2    /* No such file or directory */
#define EINTR        4    /* Interrupted system call */
#define EBADF        9    /* Bad file number */
#define ENOMEM      12    /* Out of memory */
#define EBUSY       16    /* Device or resource busy */
#define EINVAL      22    /* Invalid argument */
#define EMFILE      24    /* Too many open files */
#define EPIPE       32    /* Broken pipe */
#define ERANGE      34    /* Math result not representable */
#define EAGAIN      35    /* Resource temporarily unavailable */
#define ECONNRESET  54    /* Connection reset by peer */
#define ENOSYS      78    /* Invalid system call number */
#define EOVERFLOW   87    /* Value too large for defined data type */

#endif
