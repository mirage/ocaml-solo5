#!/bin/sh

checkopt() {
  if test -x ocaml/"$1".opt; then
    printf '.opt'
  else
    printf '.byte'
  fi
}

cat << EOF
path(solo5) = "$SYSROOT/lib"
destdir(solo5) = "$SYSROOT/lib"
stdlib(solo5) = "$SYSROOT/lib/ocaml"
ocamlopt(solo5) = "$SYSROOT/bin/ocamlopt$(checkopt ocamlopt)"
ocamlc(solo5) = "$SYSROOT/bin/ocamlc$(checkopt ocamlc)"
ocamlmklib(solo5) = "$SYSROOT/bin/ocamlmklib"
ocamldep(solo5) = "$SYSROOT/bin/ocamldep$(checkopt tools/ocamldep)"
ocamlcp(solo5) = "$SYSROOT/bin/ocamlcp"
EOF
