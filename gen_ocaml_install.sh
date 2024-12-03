#!/usr/bin/env bash

main() {
  PREFIXINSTALLFILE="$1"
  OCAMLDIR="$2"
  PREFIX="$3"

  if [ ! -d "$OCAMLDIR" ] || [ -z "$PREFIX" ]; then
    echo "Usage: $0 <prefix.file.install> <ocaml dir> <prefix>"
    exit 1
  fi

  OCAMLDIR="$(realpath "$OCAMLDIR")"
  INSTALLDIR="$(mktemp -d "$OCAMLDIR/tmp.XXXXXX")"
  ME="$(realpath "$0")"
  ln -s "$ME" "$INSTALLDIR/fake_install"
  ln -s "$ME" "$INSTALLDIR/rm"
  ln -s "$ME" "$INSTALLDIR/ln"
  ln -s "$ME" "$INSTALLDIR/fake_ocamlrun"

  export PATH="$INSTALLDIR:$PATH"
  export GEN_OCAML_INSTALL_BASEDIR="$OCAMLDIR"
  export GEN_OCAML_INSTALL_INSTALLDIR="$INSTALLDIR"
  export GEN_OCAML_INSTALL_PREFIX="$PREFIX"
  ${MAKE:-make} -C "$OCAMLDIR" \
    DESTDIR="$INSTALLDIR" \
    INSTALL_PROG="fake_install libexec" \
    INSTALL_DATA="fake_install lib" \
    OCAMLRUN=fake_ocamlrun \
    install

  mv "$INSTALLDIR/install.lib" "$PREFIXINSTALLFILE.lib"
  mv "$INSTALLDIR/install.libexec" "$PREFIXINSTALLFILE.libexec"
}

install() {
  # This argument massaging is bash-only, I think making it more portable would
  # be more verbose
  destdir="${!#}" # the last argument
  section="$1"
  set -- "${@:2:$(($# - 2))}" # all but the first and last arguments
  todrop="$GEN_OCAML_INSTALL_INSTALLDIR$GEN_OCAML_INSTALL_PREFIX/"
  destsubdir="${destdir:${#todrop}}"
  todrop="$GEN_OCAML_INSTALL_BASEDIR/"
  srcsubdir="${PWD:${#todrop}}"
  # if not empty, had a trailing `/`
  srcsubdir="${srcsubdir:+$srcsubdir/}"
  if [ ! -d "$destdir" ]; then
    # we are installing one binary under a different name
    if [ ! "$#" = 1 ]; then
      echo Unexpected install command line!
      exit 1
    fi
    f="${1#./}"
    printf '  "?ocaml/%s%s" { "%s" }\n' "$srcsubdir" "$f" "$destsubdir" >> \
      "$GEN_OCAML_INSTALL_INSTALLDIR/install.$section"
  else
    for f in "$@"; do
      printf '  "?ocaml/%s%s" { "%s" }\n' "$srcsubdir" "${f#./}" \
        "$destsubdir/$(basename "$f")" >> \
        "$GEN_OCAML_INSTALL_INSTALLDIR/install.$section"
    done
  fi
}

case "$0" in
  *fake_install)
    install "$@"
    ;;
  *rm)
    echo "Dummy rm $*"
    ;;
  *ln)
    echo "Dummy ln $*"
    ;;
  *fake_ocamlrun)
    echo "Dummy ocamlrun $*"
    ;;
  *)
    main "$@"
    ;;
esac
