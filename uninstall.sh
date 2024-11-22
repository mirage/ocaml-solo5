#!/bin/sh -ex

prefix=$1
if [ "$prefix" = "" ]; then
  prefix="$(ocamlfind query ocaml-src)/../.."
fi

odir=$prefix/lib
rm -f "$odir/findlib.conf.d/solo5.conf"
rm -rf "$prefix/solo5-sysroot"
