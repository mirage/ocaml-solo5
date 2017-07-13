#ifndef _SYS_WAIT_H
#define _SYS_WAIT_H

#define WUNTRACED 0
#define WIFSTOPPED(x) (x == 0)

pid_t waitpid(pid_t, int*, int);

#endif
