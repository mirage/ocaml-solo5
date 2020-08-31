#!/bin/sh -eu

TARGET_=$1
shift
CC_=$1
shift
CFLAGS=$@

export CC="${CC_} ${CFLAGS} -nostdlib"
export AS="as"
export ASPP="${CC_} ${CFLAGS} -c"
export LD="ld"
export CPPFLAGS="${CFLAGS}"

BUILD_ARCH="$(uname -m)"
BUILD_OS="$(uname -s)"
OCAML_BUILD_ARCH=

# Canonicalize BUILD_ARCH and set OCAML_BUILD_ARCH. The former is for autoconf,
# the latter for the rest of the OCaml build system.
case "${BUILD_ARCH}" in
    amd64|x86_64)
        BUILD_ARCH="x86_64"
        OCAML_BUILD_ARCH="amd64"
        ;;
    aarch64)
        OCAML_BUILD_ARCH="arm64"
        ;;
    *)
        echo "ERROR: Unsupported architecture: ${BUILD_ARCH}" 1>&2
        exit 1
        ;;
esac

TARGET=${BUILD_ARCH}-unknown-none

./configure --host=$TARGET

echo "ARCH=${OCAML_BUILD_ARCH}" >> Makefile.config
echo '#define HAS_GETTIMEOFDAY' >> runtime/caml/s.h
echo '#define HAS_SECURE_GETENV' >> runtime/caml/s.h
echo '#define HAS_TIMES' >> runtime/caml/s.h
echo '#undef OCAML_OS_TYPE' >> runtime/caml/s.h
echo '#define OCAML_OS_TYPE "None"' >> runtime/caml/s.h
echo '#undef HAS_SYS_SHM_H' >> runtime/caml/s.h

# FIXME: workaround unflexible install (ocaml/dune#3354
if [ -f runtime/caml/domain.h ]; then
    cp runtime/caml/domain.h .
    cp runtime/caml/domain_state.h .
    cp runtime/caml/domain_state.tbl .
else
    touch domain.h domain_state.h domain_state.tbl
fi

./tools/make-version-header.sh > version.h

cp runtime/caml/s.h runtime/caml/m.h .
