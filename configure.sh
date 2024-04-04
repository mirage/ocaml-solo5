#!/bin/sh

prog_NAME="$(basename "$0")"

err()
{
    echo "${prog_NAME}: ERROR: $*" 1>&2
}

die()
{
    echo "${prog_NAME}: ERROR: $*" 1>&2
    exit 1
}

usage()
{
    cat <<EOM 1>&2
usage: ${prog_NAME} [ OPTIONS ]
Configures the ocaml-solo5 build system.
Options:
    --prefix=DIR
        Installation prefix (default: /usr/local).
    --target=TARGET
        Solo5 compiler toolchain to use.
    --ocaml-configure-option=OPTION
        Add an option to the OCaml compiler configuration.
EOM
    exit 1
}

OCAML_CONFIGURE_OPTIONS=
MAKECONF_PREFIX=/usr/local

while [ $# -gt 0 ]; do
    OPT="$1"

    case "${OPT}" in
        --target=*)
            CONFIG_TARGET="${OPT#*=}"
            ;;
        --prefix=*)
            MAKECONF_PREFIX="${OPT#*=}"
            ;;
        --ocaml-configure-option=*)
            OCAML_CONFIGURE_OPTIONS="${OCAML_CONFIGURE_OPTIONS} ${OPT#*=}"
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

TARGET_TRIPLET="$("$CONFIG_TARGET-cc" -dumpmachine)"

case "${TARGET_TRIPLET}" in
    amd64-*|x86_64-*)
        TARGET_ARCH="x86_64"
        ;;
    aarch64-*)
        TARGET_ARCH="aarch64"
        ;;
    *)
        die "Unsupported build architecture: ${TARGET_TRIPLET}"
        ;;
esac

cat <<EOM >Makeconf
MAKECONF_PREFIX=${MAKECONF_PREFIX}
MAKECONF_TOOLCHAIN=${CONFIG_TARGET}
MAKECONF_TARGET_ARCH=${TARGET_ARCH}
MAKECONF_OCAML_CONFIGURE_OPTIONS=${OCAML_CONFIGURE_OPTIONS}
EOM
