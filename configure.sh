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
    --sysroot=DIR
        Installation prefix for the OCaml cross-compiler and its supporting
        libraries (default: <installation prefix>/lib/ocaml-solo5).
    --target=TARGET
        Solo5 compiler toolchain to use.
    --othertoolprefix=PREFIX
        Prefix for tools besides the Solo5 toolchain
        (default: \`TARGET-cc -dumpmachine\`-).
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
        --othertoolprefix=*)
            MAKECONF_TOOLPREFIX="${OPT#*=}"
            ;;
        --prefix=*)
            MAKECONF_PREFIX="${OPT#*=}"
            ;;
        --sysroot=*)
            MAKECONF_SYSROOT="${OPT#*=}"
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

MAKECONF_SYSROOT="${MAKECONF_SYSROOT:-$MAKECONF_PREFIX/lib/ocaml-solo5}"

[ -z "${CONFIG_TARGET}" ] && die "The --target option needs to be specified."

TARGET_TRIPLET="$("$CONFIG_TARGET-cc" -dumpmachine)"

MAKECONF_TOOLPREFIX="${MAKECONF_TOOLPREFIX:-$TARGET_TRIPLET-}"

# On macOS the llvm- tools (ar, ranlib, nm) live in a keg-only/MacPorts bindir
# off PATH; pin the prefix there so the build and wrappers resolve them.
if ! command -v "${MAKECONF_TOOLPREFIX}ar" >/dev/null 2>&1; then
    for bindir in \
        "$(command -v brew >/dev/null 2>&1 && brew --prefix llvm 2>/dev/null)/bin" \
        /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin \
        /opt/local/libexec/llvm-*/bin; do
        if [ -x "${bindir}/${MAKECONF_TOOLPREFIX}ar" ]; then
            MAKECONF_TOOLPREFIX="${bindir}/${MAKECONF_TOOLPREFIX}"
            break
        fi
    done
fi

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
MAKECONF_SYSROOT=${MAKECONF_SYSROOT}
MAKECONF_TOOLCHAIN=${CONFIG_TARGET}
MAKECONF_TOOLPREFIX=${MAKECONF_TOOLPREFIX}
MAKECONF_TARGET_ARCH=${TARGET_ARCH}
MAKECONF_OCAML_CONFIGURE_OPTIONS=${OCAML_CONFIGURE_OPTIONS}
EOM
