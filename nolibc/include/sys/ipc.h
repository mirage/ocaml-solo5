#ifndef _SYS_IPC_H
#define _SYS_IPC_H

typedef int uid_t;
typedef int gid_t;
typedef int mode_t;
typedef int key_t;

struct ipc_perm {
  uid_t uid;
  gid_t gid;
  uid_t cuid;
  gid_t cgid;
  mode_t mode;
};

#endif
