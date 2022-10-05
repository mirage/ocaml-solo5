#ifndef _SIGNAL_H
#define _SIGNAL_H

typedef int jmp_buf;
int setjmp(jmp_buf);
void (*signal(int sig, void (*func)(int)))(int);
#define SIG_DFL NULL
#define SIG_IGN NULL
#define SIG_ERR NULL
#define SIG_BLOCK NULL
#define SIG_SETMASK NULL
/*
 * The following definitions are not required by the OCaml runtime, but are
 * needed to build the freestanding version of GMP used by Mirage.
 */
#define SIGFPE 1
int raise(int);

typedef int sigset_t;

extern int sigfillset ();

#endif
