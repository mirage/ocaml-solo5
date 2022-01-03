#!/bin/sh -ex

prefix=$1
if [ "$prefix" = "" ]; then
  prefix=`opam var prefix`
fi

odir=$prefix/lib
rm -f $odir/findlib.conf.d/freestanding.conf
rm -rf $prefix/freestanding-sysroot
