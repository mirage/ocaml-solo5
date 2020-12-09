#!/bin/sh

prog_NAME="$(basename $0)"

err()
{
    echo "${prog_NAME}: ERROR: $@" 1>&2
}

die()
{
    echo "${prog_NAME}: ERROR: $@" 1>&2
    exit 1
}

warn()
{
    echo "${prog_NAME}: WARNING: $@" 1>&2
}

usage()
{
    cat <<EOM 1>&2
usage: ${prog_NAME} [ OPTIONS ]
Configures the ocaml-freestanding build system.
Options:
    --prefix=DIR:
        Installation prefix (default: /usr/local).
    --toolchain=TOOLCHAIN
        Solo5 toolchain flags to use.
EOM
    exit 1
}

MAKECONF_PREFIX=/usr/local
while [ $# -gt 0 ]; do
    OPT="$1"

    case "${OPT}" in
        --toolchain=*)
            CONFIG_TOOLCHAIN="${OPT##*=}"
            ;;
        --prefix=*)
            MAKECONF_PREFIX="${OPT##*=}"
            ;;
        --help)
            usage
            ;;
        *)
            err "Unknown option: '${OPT}'"
            usage
            ;;
    esac

    shift
done

[ -z "${CONFIG_TOOLCHAIN}" ] && die "The --toolchain option needs to be specified."

ocamlfind query ocaml-src >/dev/null || exit 1

MAKECONF_CFLAGS="$(solo5-config --toolchain=$CONFIG_TOOLCHAIN --cflags)"
MAKECONF_CC="$(solo5-config --toolchain=$CONFIG_TOOLCHAIN --cc)"

BUILD_ARCH="$(uname -m)"
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

PKG_CONFIG_EXTRA_LIBS=
if [ "${BUILD_ARCH}" = "aarch64" ]; then
    PKG_CONFIG_EXTRA_LIBS="$PKG_CONFIG_EXTRA_LIBS $($MAKECONF_CC -print-libgcc-file-name)" || exit 1
fi

cat <<EOM >Makeconf
MAKECONF_PREFIX=${MAKECONF_PREFIX}
MAKECONF_CFLAGS=${MAKECONF_CFLAGS}
MAKECONF_CC=${MAKECONF_CC}
MAKECONF_BUILD_ARCH=${BUILD_ARCH}
MAKECONF_OCAML_BUILD_ARCH=${OCAML_BUILD_ARCH}
MAKECONF_NOLIBC_SYSDEP_OBJS=sysdeps_solo5.o
MAKECONF_PKG_CONFIG_EXTRA_LIBS=${PKG_CONFIG_EXTRA_LIBS}
EOM
