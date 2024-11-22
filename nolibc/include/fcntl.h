#ifndef _FCNTL_H
#define _FCNTL_H

int fcntl(int, int, ...);
int open(const char *, int, ...);

/* The following values are taken from:
 * https://github.com/openbsd/src/blob/master/sys/sys/fcntl.h
 */
#define O_RDONLY  0x0000    /* open for reading only */
#define O_WRONLY  0x0001    /* open for writing only */
#define O_RDWR    0x0002    /* open for reading and writing */
#define O_APPEND  0x0008    /* set append mode */
#define O_CREAT   0x0200    /* create if nonexistent */
#define O_TRUNC   0x0400    /* truncate to zero length */
#define O_EXCL    0x0800    /* error if already exists */

#endif
