#include <solo5.h>


static char *unused_argv[] = { "mirage", NULL };

void _nolibc_init(uintptr_t heap_start, size_t heap_size); // defined in nolibc/sysdeps_solo5.c

#define CAML_NAME_SPACE
#define CAML_INTERNALS
#include <caml/callback.h>
#include <caml/startup_aux.h>
#include <caml/domain.h>

int solo5_app_main(const struct solo5_start_info *si) {
    if (Max_domains_def != 1) {
      fprintf(stderr, "expected Max_domains_def to be 1, found %d\n", Max_domains_def);
      return 1;
    };
    if (Max_domains_max != 1) {
      fprintf(stderr, "expected Max_domains_max to be 1, found %d\n", Max_domains_max);
      return 1;
    };
    _nolibc_init(si->heap_start, si->heap_size);
    caml_startup(unused_argv);
    if (caml_params->max_domains != 1) {
      fprintf(stderr, "expected max_domains to be 1, found %d\n", caml_params->max_domains);
      return 1;
    };
    return 0;
}
