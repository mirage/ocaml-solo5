#include <signal.h>

void longjmp(int, int) __attribute__ ((__noreturn__));

#define setjmp(buf) 0
