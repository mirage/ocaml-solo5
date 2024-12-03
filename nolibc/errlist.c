/* This code is mostly an extract from OpenBSD sources, keeping only the needed
 * errno values
 *
 * NOTE: the list of errors must be kept in sync with errno.h */

/*
 * Copyright (c) 1982, 1985, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <errno.h>
#include <assert.h>

const char *const sys_errlist[] = {
	"Undefined error: 0",			/* ENOERROR */
	"No such file or directory",		/* ENOENT */
	"Interrupted system call",		/* EINTR */
	"Bad file descriptor",			/* EBADF */
	"Cannot allocate memory",		/* ENOMEM */
	"Device busy",				/* EBUSY */
	"Invalid argument",			/* EINVAL */
	"Too many open files",			/* EMFILE */
	"Broken pipe",				/* EPIPE */

/* math software */
	"Result too large",			/* ERANGE */

/* non-blocking and interrupt i/o */
	"Resource temporarily unavailable",	/* EAGAIN */

/* ipc/network software -- operational errors */
	"Connection reset by peer",		/* ECONNRESET */

	"Function not implemented",		/* ENOSYS */
						/* EOVERFLOW */
	"Value too large to be stored in data type",
};

static_assert((sizeof sys_errlist/sizeof sys_errlist[0]) == NB_ERRORS,
	"errlist.c and errno.h are out of sync");
