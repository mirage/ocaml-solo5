#include <solo5.h>

#define CAML_NAME_SPACE
#include <caml/callback.h>

static char *unused_argv[] = { "mirage", NULL };

void _nolibc_init(uintptr_t heap_start, size_t heap_size); // defined in nolibc/sysdeps_solo5.c

#define CAML_INTERNALS
#include <caml/startup_aux.h>

int solo5_app_main(const struct solo5_start_info *si) {
    if (caml_params->max_domains != 1) {
      fprintf(stderr, "expected max_domains to be 1, found %d\n", caml_params->max_domains);
      return 1;
    };
    _nolibc_init(si->heap_start, si->heap_size);
    caml_startup(unused_argv);
    return 0;
}
