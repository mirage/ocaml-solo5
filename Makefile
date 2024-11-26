.PHONY: all clean install distclean ocaml

include Makeconf

all:	openlibm/libopenlibm.a nolibc/libnolibc.a ocaml solo5.conf

TOP=$(abspath .)

# CFLAGS used to build nolibc / openlibm / ocaml runtime
LOCAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/nolibc/include -include _solo5/overrides.h
# CFLAGS used by the OCaml compiler to build C stubs
GLOBAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(MAKECONF_PREFIX)/solo5-sysroot/include/nolibc/ -include _solo5/overrides.h
# LIBS used by the OCaml compiler to link executables
GLOBAL_LIBS=-L$(MAKECONF_PREFIX)/solo5-sysroot/lib/nolibc/ -lnolibc -lopenlibm $(MAKECONF_EXTRA_LIBS)

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
OC_CFLAGS=$(LOCAL_CFLAGS) -I$(TOP)/openlibm/include -I$(TOP)/openlibm/src -nostdlib
OC_LIBS=-L$(TOP)/nolibc -lnolibc -L$(TOP)/openlibm -lopenlibm -nostdlib $(MAKECONF_EXTRA_LIBS)
ocaml/Makefile.config: ocaml/Makefile openlibm/libopenlibm.a nolibc/libnolibc.a
# configure: Do not build dynlink
	sed -i -e 's/otherlibraries="dynlink"/otherlibraries=""/g' ocaml/configure
# configure: Allow precise input of flags and libs
	sed -i -e 's/oc_cflags="/oc_cflags="$$OC_CFLAGS /g' ocaml/configure
	sed -i -e 's/ocamlc_cflags="/ocamlc_cflags="$$OCAMLC_CFLAGS /g' ocaml/configure
	sed -i -e 's/nativecclibs="$$cclibs $$DLLIBS"/nativecclibs="$$GLOBAL_LIBS"/g' ocaml/configure
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
# av_cv_libm_cos=no is passed to configure to prevent -lm being used (which
# would use the host system libm instead of the freestanding openlibm, see
# https://github.com/mirage/ocaml-solo5/issues/101
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
		ac_cv_lib_m_cos="no" \
	  ./configure \
		-host=$(MAKECONF_ARCH)-unknown-none \
		-target=$(MAKECONF_BUILD_ARCH)-solo5-none \
		-prefix $(MAKECONF_PREFIX)/solo5-sysroot \
		-disable-shared\
		-disable-systhreads\
		-disable-unix-lib\
		-disable-instrumented-runtime\
		-disable-ocamltest\
		-disable-ocamldoc\
		$(MAKECONF_OCAML_CONFIGURE_OPTIONS)
	echo "ARCH=$(MAKECONF_OCAML_BUILD_ARCH)" >> ocaml/Makefile.config
	echo 'SAK_CC=cc' >> ocaml/Makefile.config
	echo 'SAK_CFLAGS=' >> ocaml/Makefile.config
	echo 'SAK_LINK=cc $(SAK_CFLAGS) $$(OUTPUTEXE)$$(1) $$(2)' >> ocaml/Makefile.config
	echo '#undef OCAML_OS_TYPE' >> ocaml/runtime/caml/s.h
	echo '#define OCAML_OS_TYPE "None"' >> ocaml/runtime/caml/s.h

# NOTE: ocaml/tools/make-version-header.sh is integrated into OCaml's ./configure script starting from OCaml 4.14
ifneq (,$(wildcard ocaml/tools/make-version-header.sh))
ocaml/runtime/caml/version.h: ocaml/Makefile.config
	ocaml/tools/make-version-header.sh > $@
else
ocaml/runtime/caml/version.h: ocaml/Makefile.config
	@
endif

ocaml: ocaml/Makefile.config ocaml/runtime/caml/version.h
	$(MAKE) -C ocaml world
	$(MAKE) -C ocaml opt

# CONFIGURATION FILES
solo5.conf: solo5.conf.in
	sed -e 's!@@PREFIX@@!$(MAKECONF_PREFIX)!' \
	    solo5.conf.in > $@

# COMMANDS
install: all
	MAKE=$(MAKE) PREFIX=$(MAKECONF_PREFIX) ./install.sh

clean:
	$(RM) -r ocaml/
	$(RM) solo5.conf
	$(MAKE) -C openlibm clean
	$(MAKE) -C nolibc \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)" \
	    "SYSDEP_OBJS=$(MAKECONF_NOLIBC_SYSDEP_OBJS)" \
	    clean

distclean: clean
	rm Makeconf
