#include <solo5.h>

#define CAML_NAME_SPACE
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>

static char *unused_argv[] = { "mirage", NULL };

void _nolibc_init(uintptr_t heap_start, size_t heap_size); // defined in nolibc/sysdeps_solo5.c

int solo5_app_main(const struct solo5_start_info *si) {
    _nolibc_init(si->heap_start, si->heap_size);
    caml_startup(unused_argv);
}
