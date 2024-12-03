#ifndef _ERRNO_H
#define _ERRNO_H

extern int errno;

/* This list of errors must be kept in sync with errlist.c */

#define ENOERROR     0 /* Actual error codes should be > 0 */

#define ENOENT       1
#define EINTR        2
#define EBADF        3
#define ENOMEM       4
#define EBUSY        5
#define EINVAL       6
#define EMFILE       7
#define EPIPE        8
#define ERANGE       9
#define EAGAIN      10
#define ECONNRESET  11
#define ENOSYS      12
#define EOVERFLOW   13

#define NB_ERRORS   14

#endif
