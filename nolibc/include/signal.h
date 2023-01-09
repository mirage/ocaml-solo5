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
 * For OCaml 5.0.0, it's not totally true. SIG_{BLOCK,SETMASK,IGN,DFL) are
 * needed by the OCaml runtime.
 *
 * NOTE: Solo5 does not implement signals, but we should not trigger
 * a situation where these values are really used.
 */
#define SIGFPE 1
int raise(int);

#endif
