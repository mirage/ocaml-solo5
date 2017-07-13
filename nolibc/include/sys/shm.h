#ifndef _SYS_SHM_H
#define _SYS_SHM_H

#include <sys/types.h>
#include <sys/time.h>
#include <sys/ipc.h>

struct shmid_ds {
    struct ipc_perm shm_perm;
    int shm_segsz;
    pid_t shm_lpid;
    pid_t shm_cpid;
    short shm_nattch;
    time_t shm_atime;
    time_t shm_dtime;
    time_t shm_ctime;
};

void *shmat(int, const void *, int);

#endif
