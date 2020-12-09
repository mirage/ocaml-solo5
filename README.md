# ocaml-freestanding -- Freestanding OCaml compiler

This package provides a freestanding OCaml compiler suitable for linking with a
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

In `PREFIX/frestanding-sysroot/bin`:

- `ocamlopt`: a native freestanding OCaml compiler configured for the chosen
  target.

In `PREFIX/frestanding-sysroot/lib/ocaml`:
- `libasmrun.a`, `libotherlibs.a`: OCaml native code runtime.
- Compiler libraries.
- In `caml/`: Header files for the OCaml runtime. 

In `PREFIX/frestanding-sysroot/lib/nolibc`:

- `libnolibc.a`: libc interfaces required by the OCaml runtime.
- `libopenlibm.a`: libm required by the OCaml runtime.

In `PREFIX/frestanding-sysroot/include/nolibc`:

- Header files for nolibc and openlibm.

In `PREFIX/lib/pkgconfig`:

- `ocaml-freestanding.pc`: package definition to link the ocaml runtime.

In `PREFIX/lib/findlib.conf.d`:

- `freestanding.conf`: ocamlfind definition of the cross-compilation switch.

### Usage

The installed compiler is not able to build executables. Instead, it can build 
_partial executables_ using the `-output-complete-obj` option. This partial 
executable can then be linked with any solo5 binding compatible with the 
configured target. It also has to be linked with the accompanying `nolibc` and 
`openlibm` libraries.

To select the `freestanding` toolchain, one can either use the `ocamlfind 
-toolchain` option or use the dune build context feature with the `(toolchain 
frestanding)`. A complete example on how to build a solo5 binary is available 
in the `test/` folder. 

### Usage - the old way (< 0.7.0):

Downstream packages should use `pkg-config --cflags ocaml-freestanding` when
compiling C code using these components and `pkg-config --libs
ocaml-freestanding` during the link step.

## Supported compiler versions

Tested against OCaml 4.10.0 through 4.11.1. Other versions may require
changing `configure.sh`.

## Porting to a different (uni)kernel base layer

Assuming your unikernel base layer is packaged for OPAM in a similar
fashion to Solo5 this should be as simple as:

1. Adding the appropriate clauses to determine the OPAM packages required
   and `MAKECONF_CFLAGS` for compilation to `configure.sh`.
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
