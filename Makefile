.PHONY: all clean install uninstall distclean ocaml

include Makeconf

all:	openlibm/libopenlibm.a nolibc/libnolibc.a ocaml ocaml-freestanding.pc freestanding.conf

TOP=$(abspath .)

# CFLAGS used to build nolibc / openlibm / ocaml runtime
LOCAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/nolibc/include -include _freestanding/overrides.h
# CFLAGS used by the OCaml compiler to build C stubs
GLOBAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(MAKECONF_PREFIX)/freestanding-sysroot/include/nolibc/ -include _freestanding/overrides.h

# NOLIBC
NOLIBC_CFLAGS=$(LOCAL_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a:
	$(MAKE) -C nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(MAKECONF_NOLIBC_SYSDEP_OBJS)"

# OPENLIBM
openlibm/libopenlibm.a:
	$(MAKE) -C openlibm "CFLAGS=$(LOCAL_CFLAGS)" libopenlibm.a

# OCAML
ocaml/Makefile:
	cp -r `ocamlfind query ocaml-src` ./ocaml

stubs/solo5_stubs.o: stubs/solo5_stubs.c
	$(MAKECONF_CC) -c $(MAKECONF_CFLAGS) -o $@ $<

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
OC_LIBS=-L$(TOP)/nolibc -lnolibc -L$(TOP)/openlibm -lopenlibm $(TOP)/stubs/solo5_stubs.o
ocaml/Makefile.config: ocaml/Makefile stubs/solo5_stubs.o openlibm/libopenlibm.a nolibc/libnolibc.a
	sed -i -e 's/runtime\/ocamlrun tools/$$(CAMLRUN) tools/g' ocaml/Makefile
	sed -i -e 's/otherlibraries="dynlink"/otherlibraries=""/g' ocaml/configure
	sed -i -e 's/oc_cflags="/oc_cflags="$$OC_CFLAGS /g' ocaml/configure
	sed -i -e 's/ocamlc_cflags="/ocamlc_cflags="$$OCAMLC_CFLAGS /g' ocaml/configure
	cd ocaml && \
		CC="$(MAKECONF_CC)" \
		OC_CFLAGS="$(OC_CFLAGS)" \
		OCAMLC_CFLAGS="$(GLOBAL_CFLAGS)" \
		AS="as" \
		ASPP="$(MAKECONF_CC) $(OC_CFLAGS) -c" \
		CPPFLAGS="$(OC_CFLAGS)" \
		LIBS="$(OC_LIBS)"\
		LD="ld" \
	  ./configure \
		-host=$(MAKECONF_BUILD_ARCH)-unknown-none \
		-prefix $(MAKECONF_PREFIX)/freestanding-sysroot \
		-disable-shared\
		-disable-unix-lib\
		-disable-instrumented-runtime\
		-disable-installing-bytecode-programs\
		-disable-installing-source-artifacts
	echo "ARCH=$(MAKECONF_OCAML_BUILD_ARCH)" >> ocaml/Makefile.config
	echo '#undef HAS_SOCKETS' >> ocaml/runtime/caml/s.h
	echo '#undef OCAML_OS_TYPE' >> ocaml/runtime/caml/s.h
	echo '#define OCAML_OS_TYPE "None"' >> ocaml/runtime/caml/s.h

ocaml/runtime/caml/version.h: ocaml/Makefile.config
	ocaml/tools/make-version-header.sh > $@

CAMLOPT:=$(shell which ocamlopt)
CAMLRUN:=$(shell which ocamlrun)
CAMLC:=$(shell which ocamlc)

ocaml: ocaml/Makefile.config ocaml/runtime/caml/version.h
	$(MAKE) -C ocaml/runtime libasmrun.a libasmrund.a ld.conf
	$(MAKE) -C ocaml/runtime libcamlrun.a libcamlrund.a -t
	$(MAKE) -C ocaml expunge ocaml ocamlc.opt ocamlopt.opt CAMLRUN=$(CAMLRUN) CAMLC=$(CAMLC) CAMLOPT=$(CAMLOPT)
	$(MAKE) -C ocaml library libraryopt CAMLRUN=$(CAMLRUN) CAMLC=$(CAMLC) CAMLOPT=$(CAMLOPT)
	
	# stub out the rest
	cp $(shell which ocamlrun) ocaml/runtime/ocamlrun
	cp $(shell which ocamlrund) ocaml/runtime/ocamlrund
	cp $(shell which ocamllex) ocaml/lex/ocamllex
	cp $(shell which ocamllex.opt) ocaml/lex/ocamllex.opt
	cp $(shell which ocamlyacc) ocaml/yacc/ocamlyacc
	touch ocaml/tools/objinfo_helper

	$(MAKE) -C ocaml ocamlyacc ocamllex -t
	$(MAKE) -C ocaml/tools objinfo_helper -t
	$(MAKE) -C ocaml/tools ocamlmklib CAMLRUN=$(CAMLRUN) CAMLC=$(CAMLC) CAMLOPT=$(CAMLOPT)
	$(MAKE) -C ocaml/tools profiling.cmx CAMLRUN=$(CAMLRUN) CAMLC=$(CAMLC) CAMLOPT=$(CAMLOPT)
	$(MAKE) -C ocaml otherlibraries otherlibrariesopt CAMLRUN=$(CAMLRUN) CAMLC=$(CAMLC) CAMLOPT=$(CAMLOPT)

# CONFIGURATION FILES
ocaml-freestanding.pc: ocaml-freestanding.pc.in Makeconf
	sed -e 's!@@PKG_CONFIG_EXTRA_LIBS@@!$(MAKECONF_PKG_CONFIG_EXTRA_LIBS)!' ocaml-freestanding.pc.in |\
	sed -e 's!@@CFLAGS@@!$(MAKECONF_CFLAGS)!' > $@

freestanding.conf: freestanding.conf.in
	sed -e 's!@@PREFIX@@!$(MAKECONF_PREFIX)!' \
	    freestanding.conf.in > $@

# COMMANDS
install: all
	PREFIX=$(MAKECONF_PREFIX) ./install.sh

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
