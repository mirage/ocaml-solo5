#!/bin/sh -eu

CC=$1
shift
CFLAGS=$@

make CC="${CC}" FREESTANDING_CFLAGS="${CFLAGS}" SYSDEP_OBJS=sysdeps_solo5.o
