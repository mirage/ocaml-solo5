.PHONY: all clean install distclean ocaml

include Makeconf

all:	openlibm/libopenlibm.a nolibc/libnolibc.a ocaml solo5.conf

TOP=$(abspath .)

# Most parts (OCaml, nolibc, openlibm) currently build their result in-tree but
# we reuse dune's `_build` dir, as familiar and already usable for `example`,
# etc., for some generated files
_build:
	mkdir -p $@

LIBS := openlibm/libopenlibm.a nolibc/libnolibc.a

# CFLAGS used to build the nolibc and openlibm libraries
LIB_CFLAGS=-I$(TOP)/nolibc/include -include _solo5/overrides.h

# NOLIBC
NOLIBC_CFLAGS=$(LIB_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a:
	$(MAKE) -C nolibc libnolibc.a \
	    "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)"

# OPENLIBM
openlibm/libopenlibm.a:
	$(MAKE) -C openlibm libopenlibm.a \
	     "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	     "CPPFLAGS=$(LIB_CFLAGS)"

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
# Extract sources from the ocaml-src package and apply patches if there any in
# `patches/<OCaml version>/`
ocaml:
# First make sure the ocaml directory doesn't exist, otherwise the cp would
# create an ocaml-src subdirectory
	test ! -d $@
	cp -r "$$(ocamlfind query ocaml-src)" $@
	VERSION="$$(head -n1 ocaml/VERSION)" ; \
	if test -d "patches/$$VERSION" ; then \
	  git apply --directory=$@ "patches/$$VERSION"/*; \
	fi

# av_cv_libm_cos=no is passed to configure to prevent -lm being used (which
# would use the host system libm instead of the freestanding openlibm, see
# https://github.com/mirage/ocaml-solo5/issues/101
ocaml/Makefile.config: $(LIBS) $(TOOLCHAIN_FOR_BUILD) | ocaml
	PATH="$$PWD/$(TOOLDIR_FOR_BUILD):$$PATH" ; \
	cd ocaml && \
	  ac_cv_lib_m_cos="no" \
	  ./configure \
		--target="$(MAKECONF_TARGET_ARCH)-solo5-ocaml" \
		--prefix="$(MAKECONF_SYSROOT)" \
		--disable-shared \
		--disable-systhreads \
		--disable-unix-lib \
		--disable-instrumented-runtime \
		--disable-debug-runtime \
		--disable-ocamltest \
		--disable-ocamldoc \
		--without-zstd \
		$(MAKECONF_OCAML_CONFIGURE_OPTIONS)

OCAML_IS_BUILT := _build/ocaml_is_built
$(OCAML_IS_BUILT): ocaml/Makefile.config | _build
	PATH="$$PWD/$(TOOLDIR_FOR_BUILD):$$PATH" $(MAKE) -C ocaml cross.opt
	cd ocaml && ocamlrun tools/stripdebug ocamlc ocamlc.tmp
	cd ocaml && ocamlrun tools/stripdebug ocamlopt ocamlopt.tmp
	touch $@

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
