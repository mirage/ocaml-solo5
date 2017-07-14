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

FREESTANDING_CFLAGS="$(pkg-config --cflags ${PKG_CONFIG_DEPS})"

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
        echo '#define INT64_LITERAL(s) s ## LL' >> config/m.x86_64.h
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
OCAML_EXTRA_DEPS=${OCAML_EXTRA_DEPS}
EOM
