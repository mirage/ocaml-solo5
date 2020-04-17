.PHONY: all clean install

include Makeconf

FREESTANDING_LIBS=build/openlibm/libopenlibm.a \
		  build/ocaml/runtime/libasmrun.a \
		  build/nolibc/libnolibc.a

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

# OCaml >= 4.08.0 uses an autotools-based build system. In this case we
# convince it to think it's using the Solo5 compiler as a cross compiler, and
# let the build system do its work with as little additional changes on our
# side as possible.
#
# Notes:
#
# - CPPFLAGS must be set for configure as well as CC, otherwise it complains
#   about headers due to differences of opinion between the preprocessor and
#   compiler.
# - ARCH must be overridden manually in Makefile.config due to the use of
#   hardcoded combinations in the OCaml configure.
# - HAS_XXX must be defined manually since our invocation of configure cannot
#   link against nolibc (which would need to produce complete Solo5 binaries).
# - We override OCAML_OS_TYPE since configure just hardcodes it to "Unix".
OCAML_CFLAGS=$(FREESTANDING_CFLAGS) -I$(TOP)/build/openlibm/include -I$(TOP)/build/openlibm/src

build/ocaml/Makefile.config: build/ocaml/Makefile
	cd build/ocaml && \
	    CC="cc $(OCAML_CFLAGS) -nostdlib" \
	    AS="as" \
	    ASPP="cc $(OCAML_CFLAGS) -c" \
	    LD="ld" \
	    CPPFLAGS="$(OCAML_CFLAGS)" \
	    ./configure --host=$(BUILD_ARCH)-unknown-none
	echo "ARCH=$(OCAML_BUILD_ARCH)" >> build/ocaml/Makefile.config
	echo '#define HAS_GETTIMEOFDAY' >> build/ocaml/runtime/caml/s.h
	echo '#define HAS_SECURE_GETENV' >> build/ocaml/runtime/caml/s.h
	echo '#define HAS_TIMES' >> build/ocaml/runtime/caml/s.h
	echo '#undef OCAML_OS_TYPE' >> build/ocaml/runtime/caml/s.h
	echo '#define OCAML_OS_TYPE "None"' >> build/ocaml/runtime/caml/s.h

build/ocaml/runtime/caml/version.h: build/ocaml/Makefile.config
	build/ocaml/tools/make-version-header.sh > $@

build/ocaml/runtime/libasmrun.a: build/ocaml/Makefile.config build/openlibm/Makefile build/ocaml/runtime/caml/version.h
	$(MAKE) -C build/ocaml/runtime libasmrun.a

build/nolibc/Makefile:
	mkdir -p build
	cp -r nolibc build

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
	awk -v RS= -- '{ \
	    sub("@@PKG_CONFIG_EXTRA_LIBS@@", "$(PKG_CONFIG_EXTRA_LIBS)", $$0); \
	    print "(", $$0, ")" \
	    }' $< >$@

flags/cflags.tmp: flags/cflags.tmp.in
	opam config subst $@

flags/cflags: flags/cflags.tmp Makeconf
	env PKG_CONFIG_PATH="$(shell opam config var prefix)/lib/pkgconfig" \
	    pkg-config $(PKG_CONFIG_DEPS) --cflags >> $<
	awk -v RS= -- '{ \
	    print "(", $$0, ")" \
	    }' $< >$@

install: all
	./install.sh

uninstall:
	./uninstall.sh

clean:
	rm -rf build config Makeconf ocaml-freestanding.pc
	rm -rf flags/libs flags/libs.tmp
	rm -rf flags/cflags flags/cflags.tmp
