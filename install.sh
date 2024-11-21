#!/bin/sh -ex

prefix="${1:-$PREFIX}"
if [ "$prefix" = "" ]; then
    prefix="$(opam var prefix)"
fi

DESTINC="${prefix}/solo5-sysroot/include/nolibc"
DESTLIB="${prefix}/solo5-sysroot/lib/nolibc"
SYSROOT="${prefix}/solo5-sysroot"
mkdir -p "${DESTINC}" "${DESTLIB}" "${SYSROOT}"

# nolibc
cp -r nolibc/include/* "${DESTINC}"
cp nolibc/libnolibc.a "${DESTLIB}"

# Openlibm
cp -r openlibm/include/*  "${DESTINC}"
cp openlibm/src/*h "${DESTINC}"
cp openlibm/libopenlibm.a "${DESTLIB}"

# OCaml
MAKE=${MAKE:=make}
${MAKE} -C ocaml install

# META: ocamlfind and other build utilities test for existance ${DESTLIB}/META
# when figuring out whether a library is installed
touch "${DESTLIB}/META"

# findlib
mkdir -p "${prefix}/lib/findlib.conf.d"
cp solo5.conf "${prefix}/lib/findlib.conf.d/solo5.conf"

# dummy packages
mkdir -p "${SYSROOT}/lib/threads"
touch "${SYSROOT}/lib/threads/META" # for ocamlfind
mkdir -p "${SYSROOT}/lib/is_solo5"
touch "${SYSROOT}/lib/is_solo5/META"
