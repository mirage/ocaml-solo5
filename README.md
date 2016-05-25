# Freestanding OCaml runtime

This package builds a freestanding OCaml runtime suitable for linking with a
unikernel base layer (currently only Solo5 is supported).

The following components are installed:

In `PREFIX/lib/ocaml-freestanding`:

- `libnolibc.a`: libc interfaces required by OCaml runtime.
- `libopenlibm.a`: libm required by OCaml runtime.
- `libasmrun.a`, `libotherlibs.a`: OCaml native code runtime.

In `PREFIX/include/ocaml-freestanding/include`:

- Header files for nolibc and openlibm.

In `PREFIX/include/ocaml-freestanding/include/caml`:

- Header files for OCaml runtime.

Downstream packages should use `pkg-config --cflags ocaml-freestanding` when
compiling C code using these components and `pkg-config --libs
ocaml-freestanding` during the link step.
