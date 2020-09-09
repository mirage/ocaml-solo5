#!/bin/sh -eu

CC=$1
shift
CFLAGS=$@

make CC="${CC}" CFLAGS="${CFLAGS}" libopenlibm.a
