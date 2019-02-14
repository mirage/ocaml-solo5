#!/bin/sh -ex

prefix=${1:-$PREFIX}
if [ "$prefix" = "" ]; then
    prefix=`opam config var prefix`
fi
DESTINC=${prefix}/include/ocaml-freestanding
DESTLIB=${prefix}/lib/ocaml-freestanding
mkdir -p ${DESTINC} ${DESTLIB}

# "nolibc"
cp -r build/nolibc/include/* ${DESTINC}
cp build/nolibc/libnolibc.a ${DESTLIB}

# Openlibm
cp -r build/openlibm/include/*  ${DESTINC}
cp build/openlibm/src/*h ${DESTINC}
cp build/openlibm/libopenlibm.a ${DESTLIB}

# Ocaml runtime
OCAML_INCLUDES="alloc.h callback.h config.h custom.h fail.h hash.h intext.h \
  memory.h misc.h mlvalues.h printexc.h signals.h compatibility.h"
mkdir -p ${DESTINC}/caml
# Prior to OCaml 4.06.0, public headers need to be cleaned up before
# installation: 'cleanup-header' uses relative paths to read headers in
# "../config", hence the nested shell and use of 'cd' here.
if [ -f build/ocaml/tools/cleanup-header ]; then
    (
        cd build/ocaml/byterun
        for f in ${OCAML_INCLUDES}; do
            sed -f ../tools/cleanup-header caml/${f} >${DESTINC}/caml/${f}
        done
    )
    cp build/ocaml/otherlibs/bigarray/bigarray.h ${DESTINC}/caml/bigarray.h
else
# Assume OCaml >= 4.06.0 here.
    OCAML_INCLUDES="${OCAML_INCLUDES} bigarray.h m.h s.h"
    for f in ${OCAML_INCLUDES}; do
        cp build/ocaml/byterun/caml/${f} ${DESTINC}/caml/${f}
    done
fi
cp build/ocaml/asmrun/libasmrun.a ${DESTLIB}/libasmrun.a

# Prior to OCaml 4.07.0, "otherlibs" contained the bigarray implementation.
# OCaml >= 4.07.0 includes bigarray as part of stdlib/libasmrun.a
if [ -f build/ocaml/otherlibs/libotherlibs.a ]; then
    cp build/ocaml/otherlibs/libotherlibs.a ${DESTLIB}/libotherlibs.a
fi

# META: ocamlfind and other build utilities test for existance ${DESTLIB}/META
# when figuring out whether a library is installed
touch ${DESTLIB}/META

# pkg-config
mkdir -p ${prefix}/lib/pkgconfig
cp ocaml-freestanding.pc ${prefix}/lib/pkgconfig/ocaml-freestanding.pc
cp flags/cflags ${DESTLIB}
cp flags/libs ${DESTLIB}
