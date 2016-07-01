ifeq ($(FREESTANDING_CFLAGS),)
    $(error FREESTANDING_CFLAGS not set)
endif
ifeq ($(SYSDEP_OBJS),)
    $(error SYSDEP_OBJS not set)
endif

CC?=cc
CFLAGS=-O2 -std=c99 -Wall -Wno-maybe-uninitialized -Wno-parentheses -Werror
CFLAGS+=$(FREESTANDING_CFLAGS)

OBJS=ctype.o \
     dtoa.o \
     memchr.o memcmp.o memcpy.o memmove.o memset.o \
     strcmp.o strlen.o strtol.o strchr.o strchrnul.o strncpy.o stpncpy.o \
     stubs.o \
     vfprintf.o vsnprintf.o snprintf.o fprintf.o printf.o

libnolibc.a: $(OBJS) $(SYSDEP_OBJS)
	$(AR) rcs $@ $(OBJS) $(SYSDEP_OBJS)

