#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

#include <sys/mman.h>

// Taken from mirage-xen
/*
 * Copyright (c) 2020 Martin Lucina <martin@lucina.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stddef.h>
#include <stdint.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>

/*
 * This is a simple bitmap allocator for virtual memory addresses. Worst-case
 * performance for bmap_alloc() is O(n), where n = total_pages / 8. bmap_free()
 * is O(1) but requires the caller to keep the size of the allocated block.
 */
typedef struct bmap_allocator {
    uint64_t *bmap;                      /* 1 bit per page; 1=free, 0=used */
    size_t bmap_size;                    /* # of words in bmap[] */
    uint64_t start_addr;                 /* starting virtual memory address */
} bmap_allocator_t;

#define BPW (sizeof(long) * 8)
_Static_assert(sizeof(long) == 8, "long must be 64 bits");

/*
 * Returns 0-based index of first set bit in (bmap[]), starting with the bit
 * index (at), or -1 if none found and end of (bmap[]) was reached.
 */
static int ffs_at(uint64_t *bmap, size_t bmap_size, size_t at)
{
    size_t word = at / BPW;
    size_t shift = at % BPW;
    size_t bit = 0;
    size_t i;

    for (i = word; i < bmap_size; i++) {
        if (i == word)
            /* (at) is not on a word boundary; shift so we can use ffsl */
            bit = __builtin_ffsl(bmap[i] >> shift);
        else
            bit = __builtin_ffsl(bmap[i]);
        if (bit)
            break;
    }

    if (bit) {
        if (i == word)
            /* Restore previous shift if any */
            bit += shift;
        return (i * BPW) + (bit - 1);
    }
    else
        return -1;
}

/*
 * Returns 0-based index of first clear bit in (bmap[]), starting with the bit
 * index (at), or -1 if none found and end of (bmap[]) was reached.
 */
static int ffc_at(uint64_t *bmap, size_t bmap_size, size_t at)
{
    size_t word = at / BPW;
    size_t shift = at % BPW;
    size_t bit = 0;
    size_t i;

    for (i = word; i < bmap_size; i++) {
        if (i == word)
            /* (at) is not on a word boundary; shift so we can use ffsl */
            bit = __builtin_ffsl(~bmap[i] >> shift);
        else
            bit = __builtin_ffsl(~bmap[i]);
        if (bit)
            break;
    }

    if (bit) {
        if (i == word)
            /* Restore previous shift if any */
            bit += shift;
        return (i * BPW) + (bit - 1);
    }
    else
        return -1;
}

/*
 * Set (n) bits in (bmap[]) at 0-based bit index (at).
 */
static void setn_at(uint64_t *bmap, size_t bmap_size, size_t at, size_t n)
{
    assert((at + n - 1) < (bmap_size * BPW));
    while (n > 0) {
        n -= 1;
        bmap[((at + n) / BPW)] |= (1UL << ((at + n) % BPW));
    }
}

/*
 * Clear (n) bits in (bmap[]) at 0-based bit index (at).
 */
static void clearn_at(uint64_t *bmap, size_t bmap_size, size_t at, size_t n)
{
    assert((at + n - 1) < (bmap_size * BPW));
    while (n > 0) {
        n -= 1;
        bmap[((at + n) / BPW)] &= ~(1UL << ((at + n) % BPW));
    }
}

/*
 * Allocate (n) pages from (alloc), returns a memory address or NULL if no
 * space found.
 */
static void *bmap_alloc(bmap_allocator_t *alloc, size_t n)
{
    int a = 0, b = 0;
    size_t bmap_bits = alloc->bmap_size * BPW;

    /*
     * Allocating 0 pages is not allowed.
     */
    assert(n >= 1);

    while (1) {
        /*
         * Look for the first free page starting at (b), initially 0.
         */
        a = ffs_at(alloc->bmap, alloc->bmap_size, (size_t)b);
        if (a < 0)
            return NULL;

        // here a is >=0
        /*
         * Look for the first used page after the found free page.
         */
        b = ffc_at(alloc->bmap, alloc->bmap_size, (size_t)a);
        if (b < 0)
            /*
             * Nothing found; all remaining pages from a..bmap_bits are free.
             */
            b = bmap_bits;

        // here both a & b are >=0 and b is greater than a
        /*
         * Is the block big enough? If yes, mark as used (0) and return it.
         */
        if ((size_t)(b - a) >= n) {
            clearn_at(alloc->bmap, alloc->bmap_size, (size_t)a, n);
            return (void *)(alloc->start_addr + (a * OCAML_SOLO5_PAGESIZE));
        }
        /*
         * Stop the search if we hit the end of bmap[] and did not find a large
         * enough block.
         */
        if ((size_t)b == bmap_bits)
            return NULL;
        /*
         * If we got here, loop with (b) set to the last seen used page.
         */
    }
}

/*
 * Free (n) pages at (addr) from (alloc).
 */
static void bmap_free(bmap_allocator_t *alloc, void *addr, size_t n)
{
    /*
     * Verify that:
     *    addr is page-aligned
     *    addr is within the range given to alloc
     *    n is at least 1; the maximum size of n is checked in setn_at().
     */
    assert(((uintptr_t)addr & (OCAML_SOLO5_PAGESIZE - 1)) == 0);
    assert((uintptr_t)addr >= alloc->start_addr);
    assert(n >= 1);

    int a = ((uintptr_t)addr - alloc->start_addr) / OCAML_SOLO5_PAGESIZE;
    setn_at(alloc->bmap, alloc->bmap_size, a, n);
}

/*
 * Initialise the allocator to use (n_pages) at (start_addr).
 */

// FIXME: this is a shared variable, should be use in critical section when used
// accross multiple domains...
static bmap_allocator_t *alloc = NULL;

void mmap_init(uint64_t start_addr, size_t n_pages)
{
    alloc = malloc(sizeof (bmap_allocator_t));
    assert(alloc != NULL);
    /*
     * n_pages must be a multiple of BPW.
     */
    assert((n_pages % BPW) == 0);
    alloc->bmap_size = n_pages / BPW;
    alloc->bmap = malloc(alloc->bmap_size * sizeof(long));
    assert(alloc->bmap);
    alloc->start_addr = start_addr;
    /*
     * All pages are initially free; set all bits in bmap[].
     */
    memset(alloc->bmap, 0xff, alloc->bmap_size * sizeof(long));
}

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t off) {

  /* The OCaml usage of [mmap()] is only to allocate some spaces, only [fildes
   * == -1] is handled so.
   */
  (void)addr; // unused argument
  (void)prot; // unused argument

  if (fildes != -1) {
    printf("mmap: file descriptor is unsupported.\n");
    abort();
  }
  if (!(flags & MAP_ANONYMOUS) || off != 0) {
    printf("mmap: only MAP_ANONYMOUS (and offset is 0) is supported.\n");
    abort();
  }

  void *ptr = bmap_alloc(alloc, len/OCAML_SOLO5_PAGESIZE);
  //printf("DEBUG: mmap: alloc for %lu @%p.\n", len, ptr);

  if (ptr == NULL) {
    // set errno
    printf("DEBUG: mmap: map failed for %lu.\n", len);
    return MAP_FAILED;
  } else {
    return ptr;
  }
}

int munmap(void *addr, size_t length)
{
  (void)length; // unused argument

  /* man page for munmap says:
   * The address addr must be a multiple of the page size (but length need not be).
   */
  if ((uintptr_t)addr & OCAML_SOLO5_PAGESIZE != 0) {
    printf("DEBUG: munmap: address %p is not aligned.\n", addr);
    errno = EINVAL;
    return -1;
  }

  //printf("DEBUG: munmap: free for %lu @%p.\n", length, addr);
  bmap_free(alloc, addr, length/OCAML_SOLO5_PAGESIZE);
  return 0;
}
