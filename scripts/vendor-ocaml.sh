#!/bin/sh -eux

OCAML_VERSIONS="4.08.0 4.08.1 4.09.0 4.09.1 4.10.0"

rm -rf ocaml

for version in ${OCAML_VERSIONS}; do
    git clone https://github.com/ocaml/ocaml.git --depth 1 -b ${version} ocaml/${version}
    rm -rf ocaml/${version}/.git
done

find ocaml -name "dune*" -delete
