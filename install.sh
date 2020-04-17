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
  memory.h misc.h mlvalues.h printexc.h signals.h compatibility.h bigarray.h \
  m.h s.h domain.h domain_state.h domain_state.tbl"
mkdir -p ${DESTINC}/caml

OCAML_RUNTIME_DIR=runtime

for f in ${OCAML_INCLUDES}; do
    src=build/ocaml/${OCAML_RUNTIME_DIR}/caml/${f}
    if [ -f ${src} ]; then
        cp ${src} ${DESTINC}/caml/${f}
    fi
done
cp build/ocaml/${OCAML_RUNTIME_DIR}/libasmrun.a ${DESTLIB}/libasmrun.a

# META: ocamlfind and other build utilities test for existance ${DESTLIB}/META
# when figuring out whether a library is installed
touch ${DESTLIB}/META

# pkg-config
mkdir -p ${prefix}/lib/pkgconfig
cp ocaml-freestanding.pc ${prefix}/lib/pkgconfig/ocaml-freestanding.pc
cp flags/cflags ${DESTLIB}
cp flags/libs ${DESTLIB}
