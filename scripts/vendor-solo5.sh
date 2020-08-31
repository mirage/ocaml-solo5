#!/bin/sh -eux

SOLO5_VERSION=v0.6.6
VERSION_H=solo5/include/solo5/solo5_version.h.distrib

rm -rf solo5
git clone https://github.com/solo5/solo5.git --depth 1 -b ${SOLO5_VERSION} solo5
rm -rf solo5/.git solo5/opam
find solo5 -name "dune*" -delete

cat <<EOM >${VERSION_H}
/* Automatically generated, do not edit */

#ifndef __VERSION_H__
#define __VERSION_H__

#define SOLO5_VERSION "${SOLO5_VERSION}"

#endif
EOM

git add -f ${VERSION_H}
