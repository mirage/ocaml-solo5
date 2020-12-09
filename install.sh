#!/bin/sh -ex

prefix=${1:-$PREFIX}
if [ "$prefix" = "" ]; then
    prefix=`opam config var prefix`
fi

DESTINC=${prefix}/freestanding-sysroot/include/nolibc
DESTLIB=${prefix}/freestanding-sysroot/lib/nolibc
SYSROOT=${prefix}/freestanding-sysroot
mkdir -p ${DESTINC} ${DESTLIB} ${SYSROOT}

# nolibc
cp -r nolibc/include/* ${DESTINC}
cp nolibc/libnolibc.a ${DESTLIB}

# Openlibm
cp -r openlibm/include/*  ${DESTINC}
cp openlibm/src/*h ${DESTINC}
cp openlibm/libopenlibm.a ${DESTLIB}

# OCaml
MAKE=${MAKE:=make}
${MAKE} -C ocaml install

# META: ocamlfind and other build utilities test for existance ${DESTLIB}/META
# when figuring out whether a library is installed
touch ${DESTLIB}/META

# pkg-config
mkdir -p ${prefix}/lib/pkgconfig
cp ocaml-freestanding.pc ${prefix}/lib/pkgconfig/ocaml-freestanding.pc

# findlib
mkdir -p ${prefix}/lib/findlib.conf.d 
cp freestanding.conf ${prefix}/lib/findlib.conf.d/freestanding.conf

# dummy packages
mkdir -p ${SYSROOT}/lib/threads
touch ${SYSROOT}/lib/threads/META # for ocamlfind
mkdir -p ${SYSROOT}/lib/is_freestanding
touch ${SYSROOT}/lib/is_freestanding/META
