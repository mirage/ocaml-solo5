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

## Supported compiler versions

Tested against OCaml 4.02.3 and 4.03.0. Other versions will require changing
`configure.sh`.

## Porting to a different (uni)kernel base layer

Assuming your unikernel base layer is packaged for OPAM in a similar
fashion to Solo5 this should be as simple as:

1. Adding the appropriate clauses to determine the OPAM packages required
   and `FREESTANDING_CFLAGS` for compilation to `configure.sh`.
2. Implementing a `nolibc/sysdeps_yourkernel.c`.

Note that the nolibc code is intentionally strict about namespacing of APIs
and header files. If your base layer exports symbols or defines types which
conflict with nolibc then the recommended course of action is to fix your
base layer to not export anything defined by "POSIX" or "standard C".
