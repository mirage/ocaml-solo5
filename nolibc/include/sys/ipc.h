#ifndef _SYS_IPC_H
#define _SYS_IPC_H

struct ipc_perm {
  uid_t uid;
  gid_t gid;
  uid_t cuid;
  gid_t cgid;
  mode_t mode;
};

#endif
