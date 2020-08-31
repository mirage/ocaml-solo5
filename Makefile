.PHONY: all clean distclean

all:
	dune build

test:
	dune test

clean:
	dune clean
