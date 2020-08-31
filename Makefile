.PHONY: all clean distclean

all:
	dune build

test:
	dune test

clean:
	dune clean

VENDORS=solo5 ocaml

vendor:
	mkdir -p vendor
	cd vendor && ../scripts/vendor-solo5.sh
	cd vendor && ../scripts/vendor-ocaml.sh
	git add vendor
	git commit vendor -m "Updating ${VENDORS}"

distclean: clean
	rm -rf vendor
