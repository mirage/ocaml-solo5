#!/bin/sh

export PKG_CONFIG_PATH=$(opam config var prefix)/lib/pkgconfig
pkg_exists() {
    pkg-config --exists "$@"
}
if pkg_exists solo5-bindings-hvt solo5-bindings-spt solo5-bindings-virtio solo5-bindings-muen solo5-bindings-genode; then
    echo "ERROR: Conflicting packages." 1>&2
    echo "ERROR: Only one of solo5-bindings-hvt, solo5-bindings-spt, solo5-bindings-virtio, solo5-bindings-muen, solo5-bindings-genode can be installed." 1>&2
    exit 1
fi
PKG_CONFIG_DEPS=
pkg_exists solo5-bindings-hvt && PKG_CONFIG_DEPS=solo5-bindings-hvt
pkg_exists solo5-bindings-spt && PKG_CONFIG_DEPS=solo5-bindings-spt
pkg_exists solo5-bindings-muen && PKG_CONFIG_DEPS=solo5-bindings-muen
pkg_exists solo5-bindings-virtio && PKG_CONFIG_DEPS=solo5-bindings-virtio
pkg_exists solo5-bindings-genode && PKG_CONFIG_DEPS=solo5-bindings-genode
if [ -z "${PKG_CONFIG_DEPS}" ]; then
    echo "ERROR: No supported Solo5 bindings package found." 1>&2
    echo "ERROR: solo5-bindings-hvt, solo5-bindings-spt, solo5-bindings-virtio, solo5-bindings-muen, or solo5-bindings-genode must be installed." 1>&2
    exit 1
fi
ocamlfind query ocaml-src >/dev/null || exit 1

FREESTANDING_CFLAGS="$(pkg-config --cflags ${PKG_CONFIG_DEPS})"
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

# TODO: Remove once we drop support for OCaml < 4.08.0
if [ ! -f config.in/Makefile.${BUILD_OS}.${OCAML_BUILD_ARCH} ]; then
    echo "ERROR: Unsupported build OS/architecture combination: ${BUILD_OS}/${OCAML_BUILD_ARCH}" 1>&2
    exit 1
fi

OCAML_4_07_0=no
OCAML_GTE_4_08_0=no
PKG_CONFIG_EXTRA_LIBS=
case $(ocamlopt -version) in
    4.06.[0-9]|4.06.[0-9]+*)
        PKG_CONFIG_EXTRA_LIBS="-lotherlibs"
        cp -r config.in config
        echo 'SYSTEM=none' >> config/Makefile.${BUILD_OS}.${BUILD_ARCH}
        ;;
    4.07.[0-9]|4.07.[0-9]+*)
        OCAML_4_07_0=yes
        cp -r config.in config
        echo 'SYSTEM=none' >> config/Makefile.${BUILD_OS}.${BUILD_ARCH}
        ;;
    4.08.[0-9]|4.08.[0-9]+*)
        OCAML_GTE_4_08_0=yes
        ;;
    4.09.[0-9]|4.09.[0-9]+*)
        OCAML_GTE_4_08_0=yes
        ;;
    *)
        echo "ERROR: Unsupported OCaml version: $(ocamlopt -version)." 1>&2
        exit 1
        ;;
esac

if [ "${BUILD_ARCH}" = "aarch64" ]; then
    PKG_CONFIG_EXTRA_LIBS="$PKG_CONFIG_EXTRA_LIBS $(gcc -print-libgcc-file-name)" || exit 1
fi

cat <<EOM >Makeconf
FREESTANDING_CFLAGS=${FREESTANDING_CFLAGS}
BUILD_ARCH=${BUILD_ARCH}
BUILD_OS=${BUILD_OS}
OCAML_BUILD_ARCH=${OCAML_BUILD_ARCH}
NOLIBC_SYSDEP_OBJS=sysdeps_solo5.o
PKG_CONFIG_DEPS=${PKG_CONFIG_DEPS}
PKG_CONFIG_EXTRA_LIBS=${PKG_CONFIG_EXTRA_LIBS}
OCAML_4_07_0=${OCAML_4_07_0}
OCAML_GTE_4_08_0=${OCAML_GTE_4_08_0}
EOM
