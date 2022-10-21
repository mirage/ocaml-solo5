#ifndef _SIGNAL_H
#define _SIGNAL_H

typedef int jmp_buf;
int setjmp(jmp_buf);
void (*signal(int sig, void (*func)(int)))(int);
#define SIG_DFL 0
#define SIG_IGN 0
#define SIG_ERR 0
#define SIG_BLOCK 0
#define SIG_SETMASK 0
/*
 * The following definitions are not required by the OCaml runtime, but are
 * needed to build the freestanding version of GMP used by Mirage.
 */
#define SIGFPE 1
int raise(int);

typedef int sigset_t;

int sigfillset(sigset_t *);

#endif
