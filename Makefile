.PHONY: all clean install uninstall distclean ocaml

include Makeconf

all:	openlibm/libopenlibm.a nolibc/libnolibc.a ocaml ocaml-freestanding.pc freestanding.conf

TOP=$(abspath .)

# CFLAGS used to build nolibc / openlibm / ocaml runtime
LOCAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/nolibc/include -include _freestanding/overrides.h
# CFLAGS used by the OCaml compiler to build C stubs
GLOBAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(MAKECONF_PREFIX)/freestanding-sysroot/include/nolibc/ -include _freestanding/overrides.h
# LIBS used by the OCaml compiler to link executables
GLOBAL_LIBS=-L$(MAKECONF_PREFIX)/freestanding-sysroot/lib/nolibc/ -lnolibc -lopenlibm $(MAKECONF_EXTRA_LIBS)

# NOLIBC
NOLIBC_CFLAGS=$(LOCAL_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a:
	$(MAKE) -C nolibc \
	    "CC=$(MAKECONF_CC)" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(MAKECONF_NOLIBC_SYSDEP_OBJS)"

# OPENLIBM
openlibm/libopenlibm.a:
	$(MAKE) -C openlibm "CC=$(MAKECONF_CC)" "CPPFLAGS=$(LOCAL_CFLAGS)" libopenlibm.a

# OCAML
ocaml/Makefile:
	cp -r `ocamlfind query ocaml-src` ./ocaml
# configure: Do not build dynlink
	sed -i -e 's/otherlibraries="dynlink"/otherlibraries=""/g' ocaml/configure
# configure: Allow precise input of flags and libs
	sed -i -e 's/oc_cflags="/oc_cflags="$$OC_CFLAGS /g' ocaml/configure
	sed -i -e 's/ocamlc_cflags="/ocamlc_cflags="$$OCAMLC_CFLAGS /g' ocaml/configure
	sed -i -e 's/nativecclibs="$$cclibs $$DLLIBS"/nativecclibs="$$GLOBAL_LIBS"/g' ocaml/configure
# Makefile: Disable build of ocamltest (for 4.10)
	sed -i -e 's/$$(MAKE) -C ocamltest all//g' ocaml/Makefile
# runtime/Makefile: Runtime rules: don't build libcamlrun.a and import ocamlrun from the system
	sed -i -e 's/^all: $$(BYTECODE_STATIC_LIBRARIES) $$(BYTECODE_SHARED_LIBRARIES)/all: primitives ld.conf/' ocaml/runtime/Makefile
	sed -i -e 's/^ocamlrun$$(EXE):.*/dummy:/g' ocaml/runtime/Makefile
	sed -i -e 's/^ocamlruni$$(EXE):.*/dummyi:/g' ocaml/runtime/Makefile
	sed -i -e 's/^ocamlrund$$(EXE):.*/dummyd:/g' ocaml/runtime/Makefile
	echo -e "ocamlrun:\n\tcp $(shell which ocamlrun) .\n" >> ocaml/runtime/Makefile
	echo -e "ocamlrund:\n\tcp $(shell which ocamlrund) .\n" >> ocaml/runtime/Makefile
	echo -e "ocamlruni:\n\tcp $(shell which ocamlruni) .\n" >> ocaml/runtime/Makefile
	touch ocaml/runtime/libcamlrun.a ocaml/runtime/libcamlrund.a ocaml/runtime/libcamlruni.a
# yacc/Makefile: import ocamlyacc from the system
	sed -i -e 's/^ocamlyacc$$(EXE):.*/dummy:/g' ocaml/yacc/Makefile
	echo -e "ocamlyacc:\n\tcp $(shell which ocamlyacc) .\n" >> ocaml/yacc/Makefile
# tools/Makefile: stub out objinfo_helper 
	echo -e "objinfo_helper:\n\ttouch objinfo_helper\n" >> ocaml/tools/Makefile

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
# - We use LIBS with a stubbed out solo5 implementation to override the OCaml 
# 	configure link test
# - We override OCAML_OS_TYPE since configure just hardcodes it to "Unix".
# - We override HAS_SOCKETS because of a bug in the ocaml configure script that
# 	always enables sockets.
OC_CFLAGS=$(LOCAL_CFLAGS) -I$(TOP)/openlibm/include -I$(TOP)/openlibm/src -nostdlib
OC_LIBS=-L$(TOP)/nolibc -lnolibc -L$(TOP)/openlibm -lopenlibm -nostdlib $(MAKECONF_EXTRA_LIBS)
ocaml/Makefile.config: ocaml/Makefile openlibm/libopenlibm.a nolibc/libnolibc.a
	cd ocaml && \
		CC="$(MAKECONF_CC)" \
		OC_CFLAGS="$(OC_CFLAGS)" \
		OCAMLC_CFLAGS="$(GLOBAL_CFLAGS)" \
		AS="$(MAKECONF_AS)" \
		ASPP="$(MAKECONF_CC) $(OC_CFLAGS) -c" \
		CPPFLAGS="$(OC_CFLAGS)" \
		LIBS="$(OC_LIBS)"\
		GLOBAL_LIBS="$(GLOBAL_LIBS)"\
		LD="$(MAKECONF_LD)" \
		ac_cv_prog_DIRECT_LD="$(MAKECONF_LD)" \
	  ./configure \
		-host=$(MAKECONF_BUILD_ARCH)-unknown-none \
		-prefix $(MAKECONF_PREFIX)/freestanding-sysroot \
		-disable-shared\
		-disable-systhreads\
		-disable-unix-lib\
		-disable-instrumented-runtime\
		$(MAKECONF_OCAML_CONFIGURE_OPTIONS)
	echo "ARCH=$(MAKECONF_OCAML_BUILD_ARCH)" >> ocaml/Makefile.config
	echo 'SAK_CC=cc' >> ocaml/Makefile.config
	echo 'SAK_CFLAGS=' >> ocaml/Makefile.config
	echo 'SAK_LINK=cc $(SAK_CFLAGS) $$(OUTPUTEXE)$$(1) $$(2)' >> ocaml/Makefile.config
	echo '#undef HAS_SOCKETS' >> ocaml/runtime/caml/s.h
	echo '#undef OCAML_OS_TYPE' >> ocaml/runtime/caml/s.h
	echo '#define OCAML_OS_TYPE "None"' >> ocaml/runtime/caml/s.h

ocaml/runtime/caml/version.h: ocaml/Makefile.config
	ocaml/tools/make-version-header.sh > $@

CAMLOPT:=$(shell which ocamlopt)
CAMLRUN:=$(shell which ocamlrun)
CAMLC:=$(shell which ocamlc)

ocaml: ocaml/Makefile.config ocaml/runtime/caml/version.h
	$(MAKE) -C ocaml world
	$(MAKE) -C ocaml opt

# CONFIGURATION FILES
ocaml-freestanding.pc: ocaml-freestanding.pc.in Makeconf
	sed -e 's!@@PKG_CONFIG_EXTRA_LIBS@@!$(MAKECONF_PKG_CONFIG_EXTRA_LIBS)!' \
	    -e 's!@@PKG_CONFIG_CC@@!$(MAKECONF_CC)!' \
	    -e 's!@@PKG_CONFIG_LD@@!$(MAKECONF_LD)!' \
		-e 's!@@PKG_CONFIG_SOLO5_TOOLCHAIN@@!$(MAKECONF_TOOLCHAIN)!' \
	    -e 's!@@CFLAGS@@!$(MAKECONF_CFLAGS)!' \
	    ocaml-freestanding.pc.in > $@

freestanding.conf: freestanding.conf.in
	sed -e 's!@@PREFIX@@!$(MAKECONF_PREFIX)!' \
	    freestanding.conf.in > $@

# COMMANDS
install: all
	MAKE=$(MAKE) PREFIX=$(MAKECONF_PREFIX) ./install.sh

uninstall:
	./uninstall.sh

clean:
	$(RM) -r ocaml/
	$(RM) ocaml-freestanding.pc freestanding.conf
	$(MAKE) -C openlibm clean
	$(MAKE) -C nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(MAKECONF_NOLIBC_SYSDEP_OBJS)" \
	    clean

distclean: clean
	rm Makeconf
