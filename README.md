# ocaml-freestanding -- Freestanding OCaml runtime

This package provides a freestanding OCaml runtime suitable for linking with a
unikernel base layer. Currently only [Solo5](https://github.com/Solo5/solo5) is
supported.

## License and contributions

All original contributions to this package are licensed under the standard MIT
license.

This package incorporates components derived or copied from musl libc, OpenBSD,
OpenLibm and other third parties. For full details of the licenses of these
third party components refer to the included LICENSE file.

The OCaml runtime ("OCaml Core System") built by this package is distributed
under the terms of the GNU LGPL version 2.1 with a special exception for static
or dynamic linking to produce an executable file. For details refer to the
LICENSE file included in the version of the `ocaml-src` OPAM package installed
on your system as a dependency when you build this package.

## Components

The following components are built and installed:

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

Tested against OCaml 4.08.0 through 4.10.0. Other versions may require
changing `configure.sh`.

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

## Updating the vendored copy of OpenLibm

OpenLibm is "vendored" into this repository using `git subtree`:

    git subtree add --prefix openlibm https://github.com/JuliaLang/openlibm.git v0.5.4 --squash

To update the vendored copy of OpenLibm to the newer upstream version `TAG`,
use the following command _on a branch_ and then file a PR:

    git subtree pull --prefix openlibm https://github.com/JuliaLang/openlibm.git TAG --squash
