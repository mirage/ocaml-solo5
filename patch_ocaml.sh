#!/bin/sh

set -eu

# Are we using GNU sed or BSD sed?
# (`sed --version` is defined only by GNU sed, btw)
# The intent is to set `sep` so that we can call `sed -i$sep''` to make it
# portable
case "$(sed --version 2>&1)" in
  *GNU*) sep='' ;;
  *) sep=' ' ;;
esac

# PATCH 1: Set `Max_domains_{def,max}` to 1
#
# Solo5 is single-core with no scheduler, so avoid the useless memory
# waste
#
# Note that since PR#13272 the maximum number of domains can set using a
# parameter in `OCAMLRUNPARAM` so a patchless implementation could be to
# add to `nolibc`:
# - a `secure_getenv` returning `"d=1"` for the `OCAMLRUNPARAM` value,
# - a `sscanf`; it could be hard-coded version just for that use case
#   (namely recover the `1`)
# but this would still be rather brittle

sed -i$sep'' \
  -e 's/#define Max_domains_def 128/#define Max_domains_def 1/' \
  -e 's/#define Max_domains_max 4096/#define Max_domains_max 1/' \
  ocaml/runtime/caml/domain.h

# PATCH 2: Use the same os_type as the host

sed -i$sep'' \
  -e 's/ostype="None"/ostype="$$(ocamlc -config-var os_type)"/' \
  ocaml/configure
