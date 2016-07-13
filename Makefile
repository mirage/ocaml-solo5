.PHONY: all clean install
FREESTANDING_LIBS=build/openlibm/libopenlibm.a \
		  build/ocaml/asmrun/libasmrun.a \
		  build/ocaml/otherlibs/libotherlibs.a \
		  build/nolibc/libnolibc.a

all:	$(FREESTANDING_LIBS)

include Makeconf

Makeconf:
	./configure.sh

TOP=$(abspath .)
FREESTANDING_CFLAGS+=-isystem $(TOP)/nolibc/include

OPENLIBM_URL=https://github.com/JuliaLang/openlibm/archive/v0.5.1.tar.gz
openlibm.tar.gz:
	curl -sL -o $@ $(OPENLIBM_URL)

build/openlibm/Makefile: openlibm.tar.gz
	mkdir -p build/openlibm
	tar -C build/openlibm --strip-components=1 -xzf openlibm.tar.gz
	touch $@

build/openlibm/libopenlibm.a: build/openlibm/Makefile
	$(MAKE) -C build/openlibm "CFLAGS=$(FREESTANDING_CFLAGS)" libopenlibm.a

build/ocaml/Makefile:
	mkdir -p build
	cp -r `ocamlfind query ocaml-src` build/ocaml

build/ocaml/config/Makefile: build/ocaml/Makefile
	cp config/s.h build/ocaml/config/s.h
	cp config/m.x86_64.h build/ocaml/config/m.h
	cp config/Makefile.x86_64 build/ocaml/config/Makefile

# Needed for OCaml 4.03.0, triggered by OCAML_EXTRA_DEPS via Makeconf
build/ocaml/byterun/caml/version.h: build/ocaml/config/Makefile
	cp config/version.h $@

OCAML_CFLAGS=-O2 -Wall -USYS_linux -DHAS_UNISTD $(FREESTANDING_CFLAGS)
OCAML_CFLAGS+=-I$(TOP)/build/openlibm/include -I$(TOP)/build/openlibm/src
build/ocaml/asmrun/libasmrun.a: build/ocaml/config/Makefile build/openlibm/Makefile $(OCAML_EXTRA_DEPS)
	$(MAKE) -C build/ocaml/asmrun \
	    UNIX_OR_WIN32=unix \
	    NATIVECCCOMPOPTS="$(OCAML_CFLAGS)" \
	    NATIVECCPROFOPTS="$(OCAML_CFLAGS)" \
	    libasmrun.a

build/ocaml/otherlibs/libotherlibs.a: build/ocaml/config/Makefile
	$(MAKE) -C build/ocaml/otherlibs/bigarray \
	    CFLAGS="$(FREESTANDING_CFLAGS) -I../../byterun" \
	    bigarray_stubs.o mmap_unix.o
	$(MAKE) -C build/ocaml/otherlibs/str \
	    CFLAGS="$(FREESTANDING_CFLAGS) -I../../byterun" \
	    strstubs.o
	$(AR) rcs $@ \
	    build/ocaml/otherlibs/bigarray/bigarray_stubs.o \
	    build/ocaml/otherlibs/bigarray/mmap_unix.o \
	    build/ocaml/otherlibs/str/strstubs.o

build/nolibc/Makefile:
	mkdir -p build
	cp -r nolibc build

NOLIBC_CFLAGS=$(FREESTANDING_CFLAGS) -isystem $(TOP)/build/openlibm/src -isystem $(TOP)/build/openlibm/include
build/nolibc/libnolibc.a: build/nolibc/Makefile build/openlibm/Makefile
	$(MAKE) -C build/nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(NOLIBC_SYSDEP_OBJS)"

ocaml-freestanding.pc: ocaml-freestanding.pc.in
	cp ocaml-freestanding.pc.in ocaml-freestanding.pc
	echo "Requires: $(PKG_CONFIG_DEPS)" >>ocaml-freestanding.pc

install: ocaml-freestanding.pc
	./install.sh

uninstall:
	./uninstall.sh

clean:
	rm -rf build openlibm.tar.gz

distclean: clean
	rm -f Makeconf openlibm.tar.gz ocaml-freestanding.pc
