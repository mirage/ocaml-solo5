#ifndef _SIGNAL_H
#define _SIGNAL_H

/*
 * The following definitions are required not only to build the OCaml runtime
 * but also the freestanding version of GMP used by Mirage.
 * Note though that Solo5 does not implement signals, so we should not trigger a
 * situation where these values are really used.
 */

typedef int jmp_buf;
int setjmp(jmp_buf);
void (*signal(int sig, void (*func)(int)))(int);
#define SIG_DFL 0
#define SIG_IGN 0
#define SIG_ERR 0
#define SIG_BLOCK 0
#define SIG_SETMASK 0

#define SIGFPE 1
int raise(int);

typedef int sigset_t;
int sigfillset(sigset_t *);
int sigwait(const sigset_t *restrict set, int *restrict sig);

#endif
