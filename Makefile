.PHONY: all clean distclean

all:
	dune build

test:
	dune test

clean:
	dune clean

ocaml:
	./scripts/vendor-ocaml.sh

distclean: clean
	rm -rf ocaml
