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
    --target=TARGET
        Solo5 compiler toolchain to use.
EOM
    exit 1
}

MAKECONF_PREFIX=/usr/local
while [ $# -gt 0 ]; do
    OPT="$1"

    case "${OPT}" in
        --target=*)
            CONFIG_TARGET="${OPT##*=}"
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

[ -z "${CONFIG_TARGET}" ] && die "The --target option needs to be specified."

ocamlfind query ocaml-src >/dev/null || exit 1

MAKECONF_CFLAGS=""
MAKECONF_CC="$CONFIG_TARGET-cc"
MAKECONF_LD="$CONFIG_TARGET-ld"
MAKECONF_AS="$MAKECONF_CC -c"

BUILD_TRIPLET="$($MAKECONF_CC -dumpmachine)"
OCAML_BUILD_ARCH=

# Canonicalize BUILD_ARCH and set OCAML_BUILD_ARCH. The former is for autoconf,
# the latter for the rest of the OCaml build system.
case "${BUILD_TRIPLET}" in
    amd64-*|x86_64-*)
        BUILD_ARCH="x86_64"
        OCAML_BUILD_ARCH="amd64"
        ;;
    aarch64-*)
        BUILD_ARCH="aarch64"
        OCAML_BUILD_ARCH="arm64"
        ;;
    *)
        echo "ERROR: Unsupported architecture: ${BUILD_TRIPLET}" 1>&2
        exit 1
        ;;
esac

EXTRA_LIBS=
if [ "${BUILD_ARCH}" = "aarch64" ]; then
    EXTRA_LIBS="$EXTRA_LIBS -lgcc" || exit 1
fi

cat <<EOM >Makeconf
MAKECONF_PREFIX=${MAKECONF_PREFIX}
MAKECONF_CFLAGS=${MAKECONF_CFLAGS}
MAKECONF_CC=${MAKECONF_CC}
MAKECONF_LD=${MAKECONF_LD}
MAKECONF_AS=${MAKECONF_AS}
MAKECONF_BUILD_ARCH=${BUILD_ARCH}
MAKECONF_OCAML_BUILD_ARCH=${OCAML_BUILD_ARCH}
MAKECONF_NOLIBC_SYSDEP_OBJS=sysdeps_solo5.o
MAKECONF_EXTRA_LIBS=${EXTRA_LIBS}
EOM
