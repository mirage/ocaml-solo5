#!/bin/sh -ex

prefix=${1:-$PREFIX}
if [ "$prefix" = "" ]; then
    prefix=`opam config var prefix`
fi
DESTINC=${prefix}/include/ocaml-freestanding
DESTLIB=${prefix}/lib/ocaml-freestanding
mkdir -p ${DESTINC} ${DESTLIB}

# "nolibc"
cp -r nolibc/include/* ${DESTINC}
cp nolibc/libnolibc.a ${DESTLIB}

# Openlibm
cp -r openlibm/include/*  ${DESTINC}
cp openlibm/src/*h ${DESTINC}
cp openlibm/libopenlibm.a ${DESTLIB}

# Ocaml runtime
CAML_DESTINC=${DESTINC}/caml
mkdir -p ${CAML_DESTINC}
cp ocaml/runtime/caml/* ${CAML_DESTINC}
cp ocaml/runtime/libasmrun.a ${DESTLIB}/libasmrun.a

# META: ocamlfind and other build utilities test for existance ${DESTLIB}/META
# when figuring out whether a library is installed
touch ${DESTLIB}/META

# pkg-config
mkdir -p ${prefix}/lib/pkgconfig
cp ocaml-freestanding.pc ${prefix}/lib/pkgconfig/ocaml-freestanding.pc
