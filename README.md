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

- `ocamlc`: a bytecode OCaml compiler configured for the chosen target. Please
  note that the bytecode runtime is not supported.
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

The installed compiler is able to build solo5 executables. The solo5 bindings 
(xen, hvt, spt, ...) is chosen at link time, using the solo5-specific 
`-z solo5-abi=XXX` compiler/linker option. Linking an executable with no 
bindings results in a _dummy_ executable.

To build with the freestanding compiler toolchain, it has to be selected using 
ocamlfind or dune:
- ocamlfind: `ocamlfind -toolchain freestanding ...`
- dune: `dune build -x freestanding`, or add the toolchain in a build context 
  in the dune workspace file.

#### Example

The `example` describes the minimal structure needed to build an 
ocaml-freestanding executable with dune, linked with the hvt bindings. It 
requires an application manifest and a startup file to initialize the libc. 

Build: `dune build -x freestanding` 
Run: `solo5-hvt _build/default.freestanding/main.exe`

### Usage - the old way (< 0.7.0):

Downstream packages should use the following flags and tools when building
and linking C code:
- CFLAGS: `pkg-config --cflags ocaml-freestanding`
- CC: `pkg-config --var=ld ocaml-freestanding`
- LIBS: `pkg-config --libs ocaml-freestanding`
- LD: `pkg-config --var=cc ocaml-freestanding`

## Supported compiler versions

Tested against OCaml 4.10.0 through 4.13.0. Other versions may require
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
