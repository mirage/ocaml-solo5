#!/bin/sh -ex

prefix=${1:-$PREFIX}
if [ "$prefix" = "" ]; then
    prefix=`opam config var prefix`
fi
DESTINC=${prefix}/include/ocaml-freestanding/include
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
# Ocaml public headers need to be cleaned up before installation:
# 'cleanup-header' uses relative paths to read headers in "../config", hence the
# nested shell and use of 'cd' here.
(
    cd build/ocaml/byterun
    for f in ${OCAML_INCLUDES}; do
	sed -f ../tools/cleanup-header caml/${f} >${DESTINC}/caml/${f}
    done
)
cp build/ocaml/asmrun/libasmrun.a ${DESTLIB}/libasmrun.a
# OCaml "otherlibs"
cp build/ocaml/otherlibs/bigarray/bigarray.h ${DESTINC}/caml/bigarray.h
cp build/ocaml/otherlibs/libotherlibs.a ${DESTLIB}/libotherlibs.a

# pkg-config
mkdir -p ${prefix}/lib/pkgconfig
cp ocaml-freestanding.pc ${prefix}/lib/pkgconfig/ocaml-freestanding.pc
