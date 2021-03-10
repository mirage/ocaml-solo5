.PHONY: all clean install uninstall distclean

include Makeconf

FREESTANDING_LIBS=openlibm/libopenlibm.a \
		  ocaml/runtime/libasmrun.a \
		  nolibc/libnolibc.a

all:	$(FREESTANDING_LIBS) ocaml-freestanding.pc

TOP=$(abspath .)
MAKECONF_CFLAGS+=-I$(TOP)/nolibc/include -include _freestanding/overrides.h

openlibm/libopenlibm.a:
	$(MAKE) -C openlibm "CC=$(MAKECONF_CC)" "CPPFLAGS=$(MAKECONF_CFLAGS)" libopenlibm.a

ocaml/Makefile:
	cp -r `ocamlfind query ocaml-src` ./ocaml

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
OCAML_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/openlibm/include -I$(TOP)/openlibm/src

ocaml/Makefile.config: ocaml/Makefile
	cd ocaml && \
	    CC="$(MAKECONF_CC) $(OCAML_CFLAGS) -nostdlib" \
	    AS="$(MAKECONF_AS)" \
	    ASPP="$(MAKECONF_CC) $(OCAML_CFLAGS) -c" \
	    LD="$(MAKECONF_LD)" \
	    CPPFLAGS="$(OCAML_CFLAGS)" \
	    ./configure --host=$(MAKECONF_BUILD_ARCH)-unknown-none
	echo "ARCH=$(MAKECONF_OCAML_BUILD_ARCH)" >> ocaml/Makefile.config
	echo 'SAK_CC=cc' >> ocaml/Makefile.config
	echo 'SAK_CFLAGS=$(OC_CFLAGS) $(OC_CPPFLAGS)' >> ocaml/Makefile.config
	echo 'SAK_LINK=$(SAK_CC) $(SAK_CFLAGS) $(OUTPUTEXE)$(1) $(2)' >> ocaml/Makefile.config
	echo '#define HAS_GETTIMEOFDAY' >> ocaml/runtime/caml/s.h
	echo '#define HAS_SECURE_GETENV' >> ocaml/runtime/caml/s.h
	echo '#define HAS_TIMES' >> ocaml/runtime/caml/s.h
	echo '#undef OCAML_OS_TYPE' >> ocaml/runtime/caml/s.h
	echo '#define OCAML_OS_TYPE "None"' >> ocaml/runtime/caml/s.h

ocaml/runtime/caml/version.h: ocaml/Makefile.config
	ocaml/tools/make-version-header.sh > $@

ocaml/runtime/libasmrun.a: ocaml/Makefile.config ocaml/runtime/caml/version.h
	$(MAKE) -C ocaml/runtime libasmrun.a

NOLIBC_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a:
	$(MAKE) -C nolibc \
		"CC=$(MAKECONF_CC)" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(MAKECONF_NOLIBC_SYSDEP_OBJS)"

ocaml-freestanding.pc: ocaml-freestanding.pc.in Makeconf
	sed -e 's!@@PKG_CONFIG_EXTRA_LIBS@@!$(MAKECONF_PKG_CONFIG_EXTRA_LIBS)!' \
	    -e 's!@@PKG_CONFIG_CC@@!$(MAKECONF_CC)!' \
	    -e 's!@@PKG_CONFIG_LD@@!$(MAKECONF_LD)!' \
	    ocaml-freestanding.pc.in > $@

install: all
	PREFIX=$(MAKECONF_PREFIX) ./install.sh

uninstall:
	./uninstall.sh

clean:
	-$(MAKE) -C ocaml/runtime clean
	$(MAKE) -C openlibm clean
	$(MAKE) -C nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(NOLIBC_SYSDEP_OBJS)" \
	    clean
	$(RM) Makeconf ocaml-freestanding.pc

distclean: clean
	$(RM) -r ocaml/
