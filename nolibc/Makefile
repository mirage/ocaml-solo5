ifeq ($(FREESTANDING_CFLAGS),)
    $(error FREESTANDING_CFLAGS not set)
endif
ifeq ($(SYSDEP_OBJS),)
    $(error SYSDEP_OBJS not set)
endif

all: libnolibc.a

.PHONY: all test-headers clean

clean:
	$(RM) libnolibc.a *.o test-include/*.[co] test-include/sys/*.[co]

CC=cc
CFLAGS=-O2 -std=c99 -Wall -Wno-parentheses -Werror
CFLAGS+=$(FREESTANDING_CFLAGS)

OBJS=assert.o \
     ctype.o \
     dtoa.o \
     memchr.o memcmp.o memcpy.o memmove.o memset.o \
     strcmp.o strlen.o strtol.o strchr.o strchrnul.o strncpy.o stpncpy.o \
     strstr.o strncmp.o \
     stubs.o \
     vfprintf.o vsnprintf.o snprintf.o fprintf.o printf.o

dtoa.o: CFLAGS+=-fno-strict-aliasing

libnolibc.a: $(OBJS) $(SYSDEP_OBJS) test-headers
	$(AR) rcs $@ $(OBJS) $(SYSDEP_OBJS)

# The following test ensures that each header file provided by nolibc is both
# self-contained and compile-tested. Note that headers in include/_freestanding
# are not intended to be included directly, thus are exempt from this check.

HEADERS=$(wildcard include/*.h include/sys/*.h)

# For each HEADER we want to test, produce test-include/HEADER.o.  Note that
# HEADER will include subdirectories, if matched.
TEST_H_OBJS=$(patsubst %.h,test-%.o,$(HEADERS))

# For each HEADER we want to test, generate a C source file including only
# that HEADER. As above, HEADER may include subdirectories.
test-include/%.c: include/%.h | test-include test-include/sys
	echo "#include \"../$<\"" >$@

.PRECIOUS: test-include/%.c

test-include:
	mkdir $@

test-include/sys:
	mkdir $@

test-headers: $(TEST_H_OBJS)
