## unreleased

* Add compatibility with the solo5 0.7.0 package split.
* Build a freestanding cross-compiler to use with the ocamlfind toolchain feature. This cross-compiler is able to build partial executables to link with a solo5 bindings library.

## v0.6.3 (2020-10-12)

* nolibc: dlmalloc: Improve security posture and robustness by always enabling assertions, initialising magic value for heap canaries using monotonic time and enabling FOOTERs. (#87, @mato)

## v0.6.2 (2020-07-22)

* Fix `posix_memalign()` return values in failure cases. (#82, @mato)

## v0.6.1 (2020-07-21)

* Add support for Solo5/xen bindings, `posix_memalign()`. (#81, @mato)
* nolibc: Implement `assert()` which was previously a no-op. (#80, @mato)

Downstream OPAM packages with C code that wish to use the interfaces/headers added in this release should depend on `ocaml-freestanding { >= 0.6.1 }`.

## v0.6.0 (2020-05-06)

* Drop support for OCaml 4.06 and 4.07. (#72, @hannesm)
* Define an `__ocaml_freestanding__` preprocessor macro, undefine leaky host toolchain preprocessor macros (`__linux__`, `__FreeBSD__`, `__OpenBSD__` et al.), provide an `<endian.h>`. (#74, @mato)
* Install all OCaml runtime headers. (#75, @hannesm)
* Provide a minimal `<inttypes.h>`. (#76, @mato, fixes #60)
* Various build system improvements and cleanups. (part of #74, #76, @mato)

Note that #74 may break downstream C code that uses `#if...#elif...#endif` chains to detect the system it is built on. Such code should be explicitly adapted to detect the presence of ocaml-freestanding by testing for the `__ocaml_freestanding__` preprocessor macro.

Further, downstream OPAM packages with C code that wish to use the interfaces/headers added in this release should depend on `ocaml-freestanding { >= 0.6.0 }`.

## v0.5.0 (2020-03-02)

* Drop support for OCaml 4.05.0. (#64, @hannesm)
* Add FreeBSD CI using Cirrus CI. (#67, @hannesm)
* Build system cleanups. Move to fully using autotools for OCaml >= 4.08.0. Improves portability to less common platforms, such as OpenBSD. (#65, @hannesm / @mato)
* OCaml 4.10.0 support. (#68, @kit-ty-kate)

## v0.4.7 (2019-09-19)

* Add support for OCaml 4.09.0 (@hannesm)

## v0.4.6 (2019-08-09)

* Fix support for OCaml 4.08.1+ (@hannesm)

## v0.4.5 (2019-07-05)

* Add support for OCaml 4.08.0 (@avsm, @hannesm, @mato)
* Add support for upcoming Solo5 "spt" target (@mato)
* dlmalloc: expose struct mallinfo and mallinfo() (@hannesm)
* Various build system changes for "non-OPAM" (dune) support (@mato, @hannesm)
* Add a link test to Travis CI (@hannesm, fixes #24)
* Remove support for OCaml < 4.05.0, matching MirageOS requirements (@hannesm)

## v0.4.4 (2019-03-17)

* Fix system compiler, add system switch to Travis CI via INSTALL\_LOCAL.
  Reverts part of #50. (@hannesm, #51).

## v0.4.3 (2019-03-14) (not published to OPAM)

* Use solo5\_abort in abort() (@hannesm, #49)
* Expose flags through files and enable the use of -runtime-variant
  (@TheLortex, #50)

## v0.4.2 (2018-11-08)

* Solo5 bindings for Genode (@ehmry, #46)

## v0.4.1 (2018-10-25)

* Migrate to OPAM2 (@hannesm, #44)
* Correctly check heap bounds if heap + stack are not contiguous (@ehmry, #43)
* Install an empty META file to keep ocamlfind etc. happy (@hannesm, #45)

## v0.4.0 (2018-09-14)

* Update to Solo5 0.4.0 OPAM package and target names (@mato, #41)

## v0.3.1 (2018-08-09)

* Support OCaml 4.07.0 (@hannesm, #39)

## v0.3.0 (2018-06-16)

* Update to Solo5 v0.3.0 APIs (@hannesm/@mato #30, #32, #34)
* Update openlibm to a844d58@master (@mato, #37)
* Add OpenBSD support (@adamsteen, #35)

## v0.2.3 (2017-11-22)

* Update dtoa.c to fix #18 (`string_of_float` incorrectly returns `-nan`)
  (@mato, #28).
* Support OCaml 4.06.0 (@mato, #27)
* Add additional stubs needed by newer gmp (@hannesm, #26)
* aarch64 support (@mato, #25)

## v0.2.2 (2017-07-14)

* Support OCaml 4.05.0 (@mato, #23)
* Fixes for OCaml 4.04.1+ (@mato, #22)
* Silence STUB: warnings by default (@mato, #19)
* Add support for solo5-kernel-muen, not exposed in Solo5 or MirageOS yet
  (@Kensan, #18)

## v0.2.1 (2017-01-18)

* Declare `OCAML_OS_TYPE` as `freestanding` (@hannesm, #14)

## v0.2.0 (2017-01-18)

* FreeBSD support (@mato, @hannesm)
* OpenLibm supplied as a git subtree (@mato, #11)
* Support OCaml 4.04.0 (@mato, #8)

## v0.1.1 (2016-07-21)

* Initial release for publishing to opam.ocaml.org.
