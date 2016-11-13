#!/bin/sh -ex

prefix=$1
if [ "$prefix" = "" ]; then
  prefix=`opam config var prefix`
fi

rm -f $prefix/share/pkgconfig/ocaml-freestanding.pc
rm -rf $prefix/lib/ocaml-freestanding
rm -rf $prefix/include/ocaml-freestanding
