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
# We have in examples/startup.c a test whether this was successful:
# - we check Max_domains_{def,max} as well as caml_params->max_domains to be 1

sed -i$sep'' \
  -e 's/#define Max_domains_def 128/#define Max_domains_def 1/' \
  -e 's/#define Max_domains_max 4096/#define Max_domains_max 1/' \
  ocaml/runtime/caml/domain.h

# PATCH 2: Use the same os_type as the host
#
# The examples/hello.exe tests this behaviour, since OCaml will complain if
# the host-provided "fmt" package is compiled with a differently checksummed
# Stdlib.

sed -i$sep'' \
  -e 's/ostype="None"/ostype="$(ocamlc -config-var os_type)"/' \
  ocaml/configure
