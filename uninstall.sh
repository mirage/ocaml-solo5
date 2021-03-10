#!/bin/sh -ex

prefix=$1
if [ "$prefix" = "" ]; then
  prefix=`opam config var prefix`
fi

odir=$prefix/lib
rm -f $odir/pkgconfig/ocaml-freestanding.pc
rm -f $odir/findlib.conf.d/freestanding.conf
rm -rf $prefix/freestanding-sysroot
