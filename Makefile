.PHONY: all clean install distclean ocaml

include Makeconf

all:	openlibm/libopenlibm.a nolibc/libnolibc.a ocaml solo5.conf

TOP=$(abspath .)

# CFLAGS used to build nolibc / openlibm / ocaml runtime
LOCAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(TOP)/nolibc/include -include _solo5/overrides.h
# CFLAGS used by the OCaml compiler to build C stubs
GLOBAL_CFLAGS=$(MAKECONF_CFLAGS) -I$(MAKECONF_PREFIX)/solo5-sysroot/include/nolibc/ -include _solo5/overrides.h
# LIBS used by the OCaml compiler to link executables
GLOBAL_LIBS=-L$(MAKECONF_PREFIX)/solo5-sysroot/lib/nolibc/ -Wl,--start-group -lnolibc -lopenlibm $(MAKECONF_EXTRA_LIBS) -Wl,--end-group

# NOLIBC
NOLIBC_CFLAGS=$(LOCAL_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a:
	$(MAKE) -C nolibc libnolibc.a \
	    "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)"

# OPENLIBM
openlibm/libopenlibm.a:
	$(MAKE) -C openlibm libopenlibm.a \
	     "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	     "CPPFLAGS=$(LOCAL_CFLAGS)"

# TOOLCHAIN
# We create prefix-gcc even when the actual compiler will be Clang because
# autoconf toolchain detection will pick the first compiler that exists in the
# list: prefix-gcc, gcc, prefix-cc, cc...
# Anyway, configure scripts always explicitly test whether the compiler defines
# Clang-specific macros when they want to distinguish GCC and Clang
ALLTOOLS := gcc cc ar as ld nm objcopy objdump ranlib readelf strip
ALLTOOLS := $(foreach tool,$(ALLTOOLS), \
                $(MAKECONF_TARGET_ARCH)-solo5-ocaml-$(tool))

TOOLDIR_FOR_BUILD := _build/build-toolchain
TOOLCHAIN_FOR_BUILD := $(addprefix $(TOOLDIR_FOR_BUILD)/,$(ALLTOOLS))
TOOLDIR_FINAL := _build/toolchain
TOOLCHAIN_FINAL := $(addprefix $(TOOLDIR_FINAL)/,$(ALLTOOLS))

# Options for the build version of the tools
TOOLCHAIN_BUILD_CFLAGS := -I$(TOP)/nolibc/include \
  -I$(TOP)/openlibm/include -I$(TOP)/openlibm/src
TOOLCHAIN_BUILD_LDFLAGS := -L$(TOP)/nolibc -L$(TOP)/openlibm

# Options for the installed version of the tools
TOOLCHAIN_FINAL_CFLAGS := -I$(MAKECONF_SYSROOT)/include
TOOLCHAIN_FINAL_LDFLAGS := -L$(MAKECONF_SYSROOT)/lib

$(TOOLDIR_FOR_BUILD) $(TOOLDIR_FINAL):
	mkdir -p $@

$(TOOLDIR_FOR_BUILD)/$(MAKECONF_TARGET_ARCH)-solo5-ocaml-%: \
    gen_toolchain_tool.sh | $(TOOLDIR_FOR_BUILD)
	ARCH="$(MAKECONF_TARGET_ARCH)" \
	  SOLO5_TOOLCHAIN="$(MAKECONF_TOOLCHAIN)" \
	  OTHERTOOLPREFIX="$(MAKECONF_TOOLPREFIX)" \
	  TOOL_CFLAGS="$(TOOLCHAIN_BUILD_CFLAGS)" \
	  TOOL_LDFLAGS="$(TOOLCHAIN_BUILD_LDFLAGS)" \
	  sh $< $* > $@
	chmod +x $@

$(TOOLDIR_FINAL)/$(MAKECONF_TARGET_ARCH)-solo5-ocaml-%: \
    gen_toolchain_tool.sh | $(TOOLDIR_FINAL)
	ARCH="$(MAKECONF_TARGET_ARCH)" \
	  SOLO5_TOOLCHAIN="$(MAKECONF_TOOLCHAIN)" \
	  OTHERTOOLPREFIX="$(MAKECONF_TOOLPREFIX)" \
	  TOOL_CFLAGS="$(TOOLCHAIN_FINAL_CFLAGS)" \
	  TOOL_LDFLAGS="$(TOOLCHAIN_FINAL_LDFLAGS)" \
	  sh $< $* > $@
	chmod +x $@

.PHONY: toolchains
toolchains: $(TOOLCHAIN_FOR_BUILD) $(TOOLCHAIN_FINAL)

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
OC_LIBS=-L$(TOP)/nolibc -lnolibc -L$(TOP)/openlibm -Wl,--start-group -lopenlibm -nostdlib $(MAKECONF_EXTRA_LIBS) -Wl,--end-group
ocaml/Makefile.config: ocaml/Makefile openlibm/libopenlibm.a nolibc/libnolibc.a
# configure: Do not build dynlink
	sed -e 's/otherlibraries="dynlink"/otherlibraries=""/g' ocaml/configure > ocaml/configure.sed && \
		mv ocaml/configure.sed ocaml/configure
# configure: Allow precise input of flags and libs
	sed -e 's/oc_cflags="/oc_cflags="$$OC_CFLAGS /g' ocaml/configure > ocaml/configure.sed && \
		mv ocaml/configure.sed ocaml/configure
	sed -e 's/ocamlc_cflags="/ocamlc_cflags="$$OCAMLC_CFLAGS /g' ocaml/configure > ocaml/configure.sed && \
		mv ocaml/configure.sed ocaml/configure
	sed -e 's/nativecclibs="$$cclibs $$DLLIBS $$PTHREAD_LIBS"/nativecclibs="$$GLOBAL_LIBS"/g' ocaml/configure > ocaml/configure.sed && \
		mv ocaml/configure.sed ocaml/configure
	sed -e 's/^arch=none$$/arch=$(MAKECONF_OCAML_BUILD_ARCH)/' ocaml/configure > ocaml/configure.sed && \
		mv ocaml/configure.sed ocaml/configure
	chmod +x ocaml/configure
# Makefile: Runtime rules: don't build libcamlrun.a and import ocamlrun from the system
	sed -e 's/^ocamlrun$$(EXE):.*/dummy:/g' ocaml/Makefile > ocaml/Makefile.sed && \
		mv ocaml/Makefile.sed ocaml/Makefile
	sed -e 's/^ocamlruni$$(EXE):.*/dummyi:/g' ocaml/Makefile > ocaml/Makefile.sed && \
		mv ocaml/Makefile.sed ocaml/Makefile
	sed -e 's/^ocamlrund$$(EXE):.*/dummyd:/g' ocaml/Makefile > ocaml/Makefile.sed && \
		mv ocaml/Makefile.sed ocaml/Makefile
	sed -e 's,^coldstart: $(COLDSTART_DEPS)$$,coldstart: runtime/primitives $$(COLDSTART_DEPS),' ocaml/Makefile > ocaml/Makefile.sed && \
		mv ocaml/Makefile.sed ocaml/Makefile
	echo -e "ocamlrun:\n\tcp $(shell which ocamlrun) .\n" >> ocaml/Makefile
	echo -e "ocamlrund:\n\tcp $(shell which ocamlrund) .\n" >> ocaml/Makefile
	echo -e "ocamlruni:\n\tcp $(shell which ocamlruni) .\n" >> ocaml/Makefile
	echo -e "runtime/ocamlrun\$$(EXE):\n\tcp $(shell which ocamlrun) runtime/\n" >> ocaml/Makefile
	echo -e "runtime/ocamlrund\$$(EXE):\n\tcp $(shell which ocamlrund) runtime/\n" >> ocaml/Makefile
	echo -e "runtime/ocamlruni\$$(EXE):\n\tcp $(shell which ocamlruni) runtime/\n" >> ocaml/Makefile
# yacc/Makefile: import ocamlyacc from the system
	sed -e 's,^$$(ocamlyacc_PROGRAM)$$(EXE):.*,dummy_yacc:,g' ocaml/Makefile > ocaml/Makefile.sed && \
		mv ocaml/Makefile.sed ocaml/Makefile
	echo -e "\$$(ocamlyacc_PROGRAM)\$$(EXE):\n\tcp $(shell which ocamlyacc) yacc/\n" >> ocaml/Makefile
# patch ocaml 5.0.0 runtime for single domain/thread solo5
	sed -e 's/#define Max_domains 128/#define Max_domains 1/' ocaml/runtime/caml/domain.h > ocaml/runtime/caml/domain.h.sed && \
		mv ocaml/runtime/caml/domain.h.sed ocaml/runtime/caml/domain.h
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
		-disable-debug-runtime\
		-disable-ocamltest\
		-disable-ocamldoc\
		$(MAKECONF_OCAML_CONFIGURE_OPTIONS)
	echo 'NATIVE_COMPILER=true' >> ocaml/Makefile.config
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
	    clean

distclean: clean
	rm Makeconf
