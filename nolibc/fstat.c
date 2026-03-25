#include <sys/types.h>
#include <string.h>
#include <time.h>

/* definition is taken from https://man.openbsd.org/stat.2 */ 
struct stat {
    dev_t           st_dev;      /* inode's device */
    ino_t           st_ino;      /* inode's number */
    mode_t          st_mode;     /* inode protection mode */
    nlink_t         st_nlink;    /* number of hard links */
    uid_t           st_uid;      /* user ID of the file's owner */
    gid_t           st_gid;      /* group ID of the file's group */
    dev_t           st_rdev;     /* device type */
    struct timespec st_atim;     /* time of last access */
    struct timespec st_mtim;     /* time of last data modification */
    struct timespec st_ctim;     /* time of last file status change */
    off_t           st_size;     /* file size, in bytes */
    blkcnt_t        st_blocks;   /* blocks allocated for file */
    blksize_t       st_blksize;  /* optimal blocksize for I/O */
    uint32_t        st_flags;    /* user defined flags for file */
    uint32_t        st_gen;      /* file generation number */
};

int fstat(int fd, struct stat *statbuf)
{
    (void)fd; /* unused */
    memset(statbuf, 0, sizeof(struct stat));
    return 0;
}
