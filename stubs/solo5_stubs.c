
void* solo5_exit;
void* solo5_clock_monotonic;
void* solo5_clock_wall;
void* solo5_console_write;
void* solo5_abort;

void* _start;
#if defined(__OpenBSD__) 
#define SSP_GUARD __guard_local
#define SSP_FAIL __stack_smash_handler
#else
#define SSP_GUARD __stack_chk_guard
#define SSP_FAIL __stack_chk_fail
#endif

void* SSP_GUARD;
void* SSP_FAIL;
