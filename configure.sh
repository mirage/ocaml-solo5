#!/bin/sh

export PKG_CONFIG_PATH=$(opam config var prefix)/lib/pkgconfig
pkg_exists() {
    pkg-config --exists "$@"
}
if pkg_exists solo5-kernel-ukvm solo5-kernel-virtio solo5-kernel-muen; then
    echo "ERROR: Conflicting packages." 1>&2
    echo "ERROR: Only one of solo5-kernel-ukvm, solo5-kernel-virtio, solo5-kernel-muen can be installed." 1>&2
    exit 1
fi
PKG_CONFIG_DEPS=
pkg_exists solo5-kernel-ukvm && PKG_CONFIG_DEPS=solo5-kernel-ukvm
pkg_exists solo5-kernel-muen && PKG_CONFIG_DEPS=solo5-kernel-muen
pkg_exists solo5-kernel-virtio && PKG_CONFIG_DEPS=solo5-kernel-virtio
if [ -z "${PKG_CONFIG_DEPS}" ]; then
    echo "ERROR: No supported kernel package found." 1>&2
    echo "ERROR: solo5-kernel-ukvm, solo5-kernel-virtio or solo5-kernel-muen must be installed." 1>&2
    exit 1
fi
ocamlfind query ocaml-src >/dev/null || exit 1

FREESTANDING_CFLAGS="$(pkg-config --cflags ${PKG_CONFIG_DEPS})"
ARCH=$(uname -m)
OS=$(uname -s)

if [ ! -f config.in/Makefile.${OS}.${ARCH} ]; then
    echo "ERROR: Unsupported host/architecture combination: ${OS}/${ARCH}" 1>&2
    exit 1
fi

PKG_CONFIG_EXTRA_LIBS=
if [ "${ARCH}" = "aarch64" ]; then
    PKG_CONFIG_EXTRA_LIBS="$(gcc -print-libgcc-file-name)" || exit 1
fi

cp -r config.in config
case $(ocamlopt -version) in
    4.02.3)
        echo '#define OCAML_OS_TYPE "Unix"' >> config/s.h
        ;;
    4.03.0)
        OCAML_EXTRA_DEPS=build/ocaml/byterun/caml/version.h
        echo '#define OCAML_OS_TYPE "Unix"' >> config/s.h
        ;;
    4.04.0|4.04.0+*)
        OCAML_EXTRA_DEPS=build/ocaml/byterun/caml/version.h
        echo '#define OCAML_OS_TYPE "freestanding"' >> config/s.h
        ;;
    4.04.[1-9]|4.04.[1-9]+*)
        OCAML_EXTRA_DEPS=build/ocaml/byterun/caml/version.h
        echo '#define OCAML_OS_TYPE "freestanding"' >> config/s.h
        echo '#define INT64_LITERAL(s) s ## LL' >> config/m.${ARCH}.h
        ;;
    4.05.[0-9]|4.05.[0-9]+*)
        OCAML_EXTRA_DEPS=build/ocaml/byterun/caml/version.h
        echo '#define OCAML_OS_TYPE "freestanding"' >> config/s.h
        echo '#define INT64_LITERAL(s) s ## LL' >> config/m.${ARCH}.h
        # Use __ANDROID__ here to disable the AFL code, otherwise we'd have to
        # add many more stubs to ocaml-freestanding.
        echo 'afl.o: CFLAGS+=-D__ANDROID__' >> config/Makefile.${OS}.${ARCH}
        ;;
    *)
        echo "ERROR: Unsupported OCaml version: $(ocamlopt -version)." 1>&2
        exit 1
        ;;
esac

cat <<EOM >Makeconf
FREESTANDING_CFLAGS=${FREESTANDING_CFLAGS}
NOLIBC_SYSDEP_OBJS=sysdeps_solo5.o
PKG_CONFIG_DEPS=${PKG_CONFIG_DEPS}
PKG_CONFIG_EXTRA_LIBS=${PKG_CONFIG_EXTRA_LIBS}
OCAML_EXTRA_DEPS=${OCAML_EXTRA_DEPS}
EOM
