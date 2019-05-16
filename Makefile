.PHONY: all clean install

include Makeconf

ifeq ($(OCAML_GTE_4_07_0),yes)
FREESTANDING_LIBS=build/openlibm/libopenlibm.a \
		  build/ocaml/asmrun/libasmrun.a \
		  build/nolibc/libnolibc.a
else
FREESTANDING_LIBS=build/openlibm/libopenlibm.a \
		  build/ocaml/asmrun/libasmrun.a \
		  build/ocaml/otherlibs/libotherlibs.a \
		  build/nolibc/libnolibc.a
endif

all:	$(FREESTANDING_LIBS) ocaml-freestanding.pc flags/libs flags/cflags

Makeconf:
	./configure.sh

TOP=$(abspath .)
FREESTANDING_CFLAGS+=-isystem $(TOP)/nolibc/include

build/openlibm/Makefile:
	mkdir -p build/openlibm
	cp -r openlibm build

build/openlibm/libopenlibm.a: build/openlibm/Makefile
	$(MAKE) -C build/openlibm "CFLAGS=$(FREESTANDING_CFLAGS)" libopenlibm.a

build/ocaml/Makefile:
	mkdir -p build
	cp -r `ocamlfind query ocaml-src` build/ocaml

build/ocaml/config/Makefile: build/ocaml/Makefile
ifeq ($(OCAML_GTE_4_06_0),yes)
	cp config/s.h build/ocaml/byterun/caml/s.h
	cp config/m.$(BUILD_ARCH).h build/ocaml/byterun/caml/m.h
else
	cp config/s.h build/ocaml/config/s.h
	cp config/m.$(BUILD_ARCH).h build/ocaml/config/m.h
endif
	cp config/Makefile.$(BUILD_OS).$(BUILD_ARCH) build/ocaml/config/Makefile

# Needed for OCaml >= 4.03.0, triggered by OCAML_EXTRA_DEPS via Makeconf
build/ocaml/byterun/caml/version.h: build/ocaml/config/Makefile
	build/ocaml/tools/make-version-header.sh > $@

OCAML_CFLAGS=-O2 -fno-strict-aliasing -fwrapv -Wall -USYS_linux -DHAS_UNISTD $(FREESTANDING_CFLAGS)
OCAML_CFLAGS+=-I$(TOP)/build/openlibm/include -I$(TOP)/build/openlibm/src
build/ocaml/asmrun/libasmrun.a: build/ocaml/config/Makefile build/openlibm/Makefile $(OCAML_EXTRA_DEPS)
ifeq ($(OCAML_GTE_4_06_0),yes)
	$(MAKE) -C build/ocaml/asmrun \
	    UNIX_OR_WIN32=unix \
	    CFLAGS="$(OCAML_CFLAGS)" \
	    libasmrun.a
else
	$(MAKE) -C build/ocaml/asmrun \
	    UNIX_OR_WIN32=unix \
	    NATIVECCCOMPOPTS="$(OCAML_CFLAGS)" \
	    NATIVECCPROFOPTS="$(OCAML_CFLAGS)" \
	    libasmrun.a
endif

build/ocaml/otherlibs/libotherlibs.a: build/ocaml/config/Makefile
ifeq ($(OCAML_GTE_4_06_0),yes)
	$(MAKE) -C build/ocaml/otherlibs/bigarray \
	    OUTPUTOBJ=-o \
	    CFLAGS="$(FREESTANDING_CFLAGS) -DIN_OCAML_BIGARRAY -I../../byterun" \
	    bigarray_stubs.o mmap_ba.o mmap.o
	$(AR) rcs $@ \
	    build/ocaml/otherlibs/bigarray/bigarray_stubs.o \
	    build/ocaml/otherlibs/bigarray/mmap_ba.o \
	    build/ocaml/otherlibs/bigarray/mmap.o
else
	$(MAKE) -C build/ocaml/otherlibs/bigarray \
	    CFLAGS="$(FREESTANDING_CFLAGS) -I../../byterun" \
	    bigarray_stubs.o mmap_unix.o
	$(AR) rcs $@ \
	    build/ocaml/otherlibs/bigarray/bigarray_stubs.o \
	    build/ocaml/otherlibs/bigarray/mmap_unix.o
endif

build/nolibc/Makefile:
	mkdir -p build
	cp -r nolibc build
ifeq ($(OCAML_GTE_4_07_0),yes)
	echo '/* automatically added by configure.sh */' >> build/nolibc/stubs.c
	echo 'STUB_ABORT(caml_ba_map_file);' >> build/nolibc/stubs.c
endif

NOLIBC_CFLAGS=$(FREESTANDING_CFLAGS) -isystem $(TOP)/build/openlibm/src -isystem $(TOP)/build/openlibm/include
build/nolibc/libnolibc.a: build/nolibc/Makefile build/openlibm/Makefile
	$(MAKE) -C build/nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(NOLIBC_SYSDEP_OBJS)"

ocaml-freestanding.pc: ocaml-freestanding.pc.in Makeconf
	sed -e 's!@@PKG_CONFIG_DEPS@@!$(PKG_CONFIG_DEPS)!' \
	    -e 's!@@PKG_CONFIG_EXTRA_LIBS@@!$(PKG_CONFIG_EXTRA_LIBS)!' \
	    ocaml-freestanding.pc.in > $@

flags/libs.tmp: flags/libs.tmp.in
	opam config subst $@

flags/libs: flags/libs.tmp Makeconf
	env PKG_CONFIG_PATH="$(shell opam config var prefix)/lib/pkgconfig" \
	    pkg-config $(PKG_CONFIG_DEPS) --libs >> $<
	sed -e '1i (' \
            -e 's!@@PKG_CONFIG_EXTRA_LIBS@@!$(PKG_CONFIG_EXTRA_LIBS)!' \
	    -e '$$a )' \
	    $< > $@

flags/cflags.tmp: flags/cflags.tmp.in
	opam config subst $@

flags/cflags: flags/cflags.tmp Makeconf
	env PKG_CONFIG_PATH="$(shell opam config var prefix)/lib/pkgconfig" \
	    pkg-config $(PKG_CONFIG_DEPS) --cflags >> $<
	sed -e '1i (' \
	    -e '$$a )' \
	    $< > $@

install: all
	./install.sh

uninstall:
	./uninstall.sh

clean:
	rm -rf build config Makeconf ocaml-freestanding.pc
	rm -rf flags/libs flags/libs.tmp
	rm -rf flags/cflags flags/cflags.tmp
