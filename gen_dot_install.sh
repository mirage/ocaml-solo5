#!/bin/sh

if [ ! -e "$1.lib" ] || [ ! -e "$1.libexec" ]; then
  echo "Usage: $0 <prefix.file.install>"
  echo "The *.install.lib and *.install.libexec for OCaml must be available."
  exit 1
fi

prefix_for_ocaml_chunks="$1"
shift

install_file() {
  # install_file <src> [dest]
  if [ -z "$2" ]; then
    printf '  "%s"\n' "$1"
  else
    printf '  "%s" { "%s" }\n' "$1" "$2"
  fi
}

walk_tree() {
  # walk_tree <srcprefix> <destprefix> [extension]
  # where *prefix are not empty
  for f in "$1"/*"$3"; do
    base="${f##*/}"
    if [ -d "$f" ]; then
      walk_tree "$f" "$2/$base" "$3"
    else
      install_file "$f" "$2/$base"
    fi
  done
}

main() {
  printf '%s: [\n' bin
  for f in "$@"; do
    install_file "$f"
  done
  printf ']\n'

  printf '%s: [\n' lib_root
  install_file _build/solo5.conf findlib.conf.d/solo5.conf
  printf ']\n'

  printf '%s: [\n' libexec
  cat "$prefix_for_ocaml_chunks".libexec
  printf ']\n'

  printf '%s: [\n' lib
  cat "$prefix_for_ocaml_chunks".lib
  walk_tree nolibc/include include
  install_file nolibc/libnolibc.a lib/libnolibc.a
  walk_tree openlibm/include include
  walk_tree openlibm/src include .h
  install_file openlibm/libopenlibm.a lib/libopenlibm.a
  # dummy packages
  for pkg in nolibc threads is_solo5; do
    install_file _build/empty-META lib/$pkg/META
  done
  printf ']\n'
}

# The only arguments left are the toolchain tools
main "$@"
