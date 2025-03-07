include Makeconf

# The `all` target is moved to the end to use variables in its dependencies
.PHONY: default
default: all

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
# Use a phony target indirection, so that nolibc/Makefile is always checked to
# see whether the library should be rebuilt while avoiding useless rebuild if
# nolibc/libnolibc.a was up-to-date
NOLIBC_CFLAGS=$(LIB_CFLAGS) -I$(TOP)/openlibm/src -I$(TOP)/openlibm/include
nolibc/libnolibc.a: phony-nolibc

.PHONY: phony-nolibc
phony-nolibc:
	$(MAKE) -C nolibc libnolibc.a \
	    "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)"

# OPENLIBM
# See NOLIBC for explanations of the phony target
openlibm/libopenlibm.a: phony-openlibm

.PHONY: phony-openlibm
phony-openlibm:
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

ocaml/Makefile.config: $(LIBS) $(TOOLCHAIN_FOR_BUILD) | ocaml
	PATH="$$PWD/$(TOOLDIR_FOR_BUILD):$$PATH" ; \
	cd ocaml && \
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
	PATH="$$PWD/$(TOOLDIR_FOR_BUILD):$$PATH" \
	  $(MAKE) -C ocaml crossopt OLDS="-o yacc/ocamlyacc -o lex/ocamllex"
	touch $@

# CONFIGURATION FILES
_build/solo5.conf: gen_solo5_conf.sh $(OCAML_IS_BUILT)
	PREFIX="$(MAKECONF_PREFIX)" SYSROOT="$(MAKECONF_SYSROOT)" ./gen_solo5_conf.sh > $@

_build/empty-META: | _build
	touch $@

# INSTALL
PACKAGES := $(basename $(wildcard *.opam))
INSTALL_FILES := $(foreach pkg,$(PACKAGES),$(pkg).install)

$(INSTALL_FILES): $(TOOLCHAIN_FINAL)
	./gen_dot_install.sh $(TOOLCHAIN_FINAL) > $@

# COMMANDS
.PHONY: install-ocaml
install-ocaml:
	ln -sf "$$(command -v ocamllex)" ocaml/lex/ocamllex
	ln -sf "$$(command -v ocamlyacc)" ocaml/yacc/ocamlyacc
	$(MAKE) -C ocaml installcross

PACKAGE := ocaml-solo5
.PHONY: install
install: $(PACKAGE).install install-ocaml
	opam-installer --prefix=$(MAKECONF_PREFIX) $<

.PHONY: clean
clean:
	$(RM) -rf _build
	$(MAKE) -C openlibm clean
	$(MAKE) -C nolibc clean FREESTANDING_CFLAGS=_
	if [ -d ocaml ] ; then $(MAKE) -C ocaml clean ; fi
	$(RM) -f $(INSTALL_FILES)

.PHONY: distclean
distclean: clean
	$(RM) -f Makeconf
# Don't remove the ocaml directory itself, to play nicer with
# development in there
	if [ -d ocaml ] ; then $(MAKE) -C ocaml distclean ; fi

.PHONY: all
all: $(LIBS) $(OCAML_IS_BUILT) \
     _build/solo5.conf _build/empty-META \
     $(TOOLCHAIN_FINAL)

.PHONY: test
test:
	$(MAKE) -C nolibc test-headers \
	    "CC=$(MAKECONF_TOOLCHAIN)-cc" \
	    "FREESTANDING_CFLAGS=$(NOLIBC_CFLAGS)"
