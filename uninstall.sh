#!/bin/sh -ex

prefix=$1
if [ "$prefix" = "" ]; then
  prefix=`opam var prefix`
fi

odir=$prefix/lib
rm -f $odir/pkgconfig/ocaml-freestanding.pc
rm -rf $odir/ocaml-freestanding
rm -rf $prefix/include/ocaml-freestanding
