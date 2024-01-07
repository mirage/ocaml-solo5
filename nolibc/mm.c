/*
 * Copyright (c) 2020 Martin Lucina <martin@lucina.net>
 * Copyright (c) 2023 Pierre Alain <pierre.alain@tuta.io>
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

#include <assert.h>
#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#if 0
#define DPRINTF(format, ...) printf("%s(): " format, __func__, __VA_ARGS__)
#else
#define DPRINTF(format, ...)
#endif

// total memory currently in use
static size_t memory_usage = 0;

/*********************** BITMAP ALLOCATOR ***********************/
/*
 * This is a simple bitmap allocator for virtual memory addresses. Worst-case
 * performance for bmap_alloc() is O(n), where n = total_pages / 8. bmap_free()
 * is O(1) but requires the caller to keep the size of the allocated block.
 * The algorithm memory usage is sizeof(bmap_allocator_t)+1 bit/page =>
 *   64MB takes around 16kB
 */
typedef struct bmap_allocator {
    uint64_t *bmap;                      /* 1 bit per page; 1=free, 0=used */
    size_t bmap_size;                    /* # of words in bmap[] */
    uint64_t start_addr;                 /* starting virtual memory address */
} bmap_allocator_t;

#define BPW sizeof(uint64_t)

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
    memory_usage -= n*OCAML_SOLO5_PAGESIZE;
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
    memory_usage += n*OCAML_SOLO5_PAGESIZE;
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
        if (a < 0) {
            printf("Memory is full!\n");
            // abort(); //?
            return NULL;
        }

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
        if ((size_t)b == bmap_bits) {
            return NULL;
        }
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

/*********************** BUDDY ALLOCATOR ************************/

/* This allocator is used for small requests splitting a
 * OCAML_SOLO5_PAGESIZE area (4096B) into 128 parts (this will serves
 * at least 32B of memory per block and permits to store indexes on a
 * single byte).
 * The total size for managing a page is 4+8+128*3 = 396 bytes... not
 * really efficient in term of memory usage but a simple implementation
 *
 * For a detailed description of this binary buddy allocation algorithm
 * please refers to :
 *     The Art of Computer Programming Vol.1
 *     The buddy system p.442
 */


// total size of memory 2^LOG2_NR_PAGES * BLOCK_SIZE. This is 'm' in TAOCP
#define LOG2_NR_PAGES 7
#define BUDDY_BLOCK_SIZE 32

// type blk_idx stands for a block number index
typedef uint8_t blk_idx;
// ALPHA is a special constant that stands for NULL with linked lists
#define ALPHA ((blk_idx)-1)

/* a node element in a double linked list of free nodes (we have a list for
 * every blocks sizes)
 */
struct buddy_node
{
    uint8_t available:1; // 0 = used, 1 = free
    uint8_t size:5; // size of a block (memory available = 2^size, here 2^5=32 >= LOG2_NR_PAGES)
    uint8_t filler:2; // not used yet
    blk_idx backward; // # of next node in the linked list
    blk_idx forward; // # of backward node in the linked list
};

/* header of our page buddy system, this is a node in a single list of pages used as buddy system */
typedef struct buddy_header
{
    uintptr_t start; // the start of our available memory area (i.e. page address)
    blk_idx avail[LOG2_NR_PAGES+1];
    uint8_t max_available;
    struct buddy_node blocks[1<<LOG2_NR_PAGES];
} buddy_allocator_t;

static void* block_to_address(buddy_allocator_t* h, blk_idx block)
{
    DPRINTF("blk %d + start addr %p => addr %p\n", block, (void*)(h->start), (void*)(h->start + block*BUDDY_BLOCK_SIZE));
	return (void*)(h->start + block*BUDDY_BLOCK_SIZE);
}

static blk_idx address_to_block(buddy_allocator_t* h, void *addr)
{
	blk_idx idx = (blk_idx)(((uintptr_t)addr - h->start)/BUDDY_BLOCK_SIZE);
	assert(addr == (void*)(h->start + idx*BUDDY_BLOCK_SIZE));
    DPRINTF("blk %d + start addr %p => addr %p\n", idx, (void*)(h->start), (void*)(h->start + idx*BUDDY_BLOCK_SIZE));
	return idx;
}

static void buddy_pushfront(buddy_allocator_t* h, blk_idx block, uint8_t k)
{
    h->blocks[block].available = 1;
    h->blocks[block].size = k;
    h->blocks[block].forward = h->avail[k];
    h->blocks[block].backward = ALPHA;

    if (h->avail[k] != ALPHA)
        h->blocks[h->avail[k]].backward = block;

    h->avail[k] = block;
}

static blk_idx buddy_popfront(buddy_allocator_t* h, uint8_t k)
{
    assert(h->avail[k]!=ALPHA);

    blk_idx current = h->avail[k];
    h->avail[k] = h->blocks[current].forward;

    return current;
}

static void buddy_remove(buddy_allocator_t* h, blk_idx block, uint8_t k)
{
    blk_idx backward = h->blocks[block].backward;
    blk_idx forward = h->blocks[block].forward;

    h->blocks[block].backward = ALPHA;
    h->blocks[block].forward = ALPHA;
    h->blocks[block].available = 1;

    if (backward != ALPHA)
        h->blocks[backward].forward = forward;
    else h->avail[k] = forward;

    if (forward!=ALPHA)
        h->blocks[forward].backward = backward;
}

static void* buddy_alloc(buddy_allocator_t* h, uint8_t count)
{
    assert(count > 0 && count <= 128);
    // we need the exponent position of the immediate upper power of two
    uint8_t k = 8*sizeof(unsigned int) - (__builtin_clz((unsigned int)count));

    DPRINTF("searching for %d blocks, total size requested %ds, total size used %d, with k=%d\n", count, count*BUDDY_BLOCK_SIZE, k*BUDDY_BLOCK_SIZE, k);
    if (k > LOG2_NR_PAGES) return NULL;

    // search for the 'j' (k <= j <= m) that have a free block (size=2^j)
    // R1 instructions p.443
    uint8_t j = k;
    while (!(j == LOG2_NR_PAGES+1 || h->avail[j] != ALPHA))
    {
        ++j;
    }
    // if no suitable 'j'
    if (j == LOG2_NR_PAGES+1) {
        h->max_available = 0;
        return NULL;
    }

    // else we have to split the avail[j] block in smaller ones
    // R2 instructions
    blk_idx block = buddy_popfront(h, j);

    if (1<<j == h->max_available && h->avail[j] == ALPHA) // update the greatest block size available
    {
        uint8_t i = j;
        while(!(i == 0 || h->avail[i] != ALPHA))
        {
            --i;
        }
        h->max_available = 1<<i;
    }

    DPRINTF("block index is %d\n", block);

    while (!(j == k))
    {
        // R4 instructions
        --j;
        buddy_pushfront(h, (blk_idx)(block+(1<<j)), j);
    }
    // and finally we have the block at index block with a correct size
    // R3 condition
    h->blocks[block].available = 0;
    h->blocks[block].size = k;

    return block_to_address(h, block);
}

static void buddy_free(buddy_allocator_t* h, void* addr)
{
    blk_idx block = address_to_block(h, addr);
    uint8_t k = h->blocks[block].size;
    assert(k<=LOG2_NR_PAGES);

    blk_idx buddy_block;

    // find our buddy block (Eq.10 p.442)
    buddy_block = block ^ (1<<k);

    // if we can merge this block and its buddy (S1 condition p.444)
    while(!(k == LOG2_NR_PAGES || h->blocks[buddy_block].available == 0 || h->blocks[buddy_block].size != k))
    {
        // S2 instructions
        buddy_remove(h, buddy_block, k);
        ++k;

        if(buddy_block<block) block=buddy_block;

        // update the buddy block
        buddy_block = block ^ (1<<k);
    }
    // S3
    buddy_pushfront(h, block, k);
    if (1<<k > h->max_available) // update the greatest block size available
        h->max_available = 1<<k;
}

static void buddy_init(buddy_allocator_t *h, size_t n, uintptr_t start_addr)
{
    h[n].start = start_addr;

    for (size_t i=0; i<=LOG2_NR_PAGES; ++i)
    {
        h[n].avail[i] = ALPHA;
    }
    buddy_pushfront(&(h[n]), 0, LOG2_NR_PAGES);
    h[n].max_available = 1<<LOG2_NR_PAGES;
}

/*********************** KEEP A LIST OF MEMORY ALLOCATED ********/
/* This is a list for dealing with large malloc request to store the number of page
 *  (this is an array that growth to the left : the first element is always at index
 *  nla_alloc and adding an element is done by putting the element at la_alloc,
 *  decreasing the location of the array by sizeof(keep_length_t), and 
 *  increasing the size)
 * Note: As it's an array we can't simply remove unsed elements, so I use addr = NULL
 * for a free element (that could be used when pushing a new element)
 */
typedef struct keep_length
{
    void* addr;
    size_t length; // number of pages allocated at address addr
} keep_length_t;

static void push_length(keep_length_t** len_array, size_t* len_count, void* addr, size_t len)
{
    DPRINTF("push addr %p with len %lu\n", addr, len);
    // search for a free cell in the array
    size_t i = *len_count;
    while (!(i == 0 || (*len_array)[i].addr == NULL))
    {
        DPRINTF("looking at %lu %p %lu\n", i, (*len_array)[i].addr, (*len_array)[i].length);
        --i;
    }

    DPRINTF("found at %lu\n", i);
    (*len_array)[i].addr = addr;
    (*len_array)[i].length = len;
    if (i == 0) // no free cell, decrease the starting position, init the new 0's cell
    {
        (*len_array) -= 1; // due to pointer arithmetics, only decrease 1
        (*len_array)[0].addr = NULL;
        (*len_array)[0].length = 0;
        (*len_count) ++;
    }
    DPRINTF("added at %lu %p %lu\n", i+1, (*len_array)[i+1].addr, (*len_array)[i+1].length);

}

static uint16_t pop_length(keep_length_t* len_array, size_t len_count, void* addr)
{
    DPRINTF("pop  addr %p\n", addr);
    // search for a matching cell in the array
    size_t i = len_count;
    while (!(i == 0 || len_array[i].addr == addr))
    {
        DPRINTF("looking at %lu %p %lu\n", i, (len_array)[i].addr, (len_array)[i].length);
        --i;
    }

    // if not found we are in troubles :(
    assert(i!=0);
    DPRINTF("found with len %lu\n", len_array[i].length);

    // release this cell
    len_array[i].addr = NULL;
    return len_array[i].length;
}

/*********************** INIT MEMORY MANAGER ********************/

/*
 * Initialise the allocator to use (n_pages) at (start_addr).
 */

/* WARNING: those are a shared variables, should be use in critical section
 * when used accross multiple domains... So far ocaml-solo5 only support a
 * single running core
 */
// bitmap allocator
static bmap_allocator_t *bm_alloc = NULL;
// buddy system allocator (this is an array that growth to the right)
static buddy_allocator_t *bu_alloc = NULL;
static size_t nbu_alloc = 0;
// list of address+length allocated by malloc/...
static keep_length_t* la_alloc = NULL;
static size_t nla_alloc = 0;

/* We keep 1MB of memory at bottom of the heap for the memory manager
 * This gives 256 pages of 4096B
 * The medata data is stored as:
 *   - bmap_allocator struct + bmap (approx. memory_size/PAGE_SIZE)
 *   - buddy_alloctator struct (approx 400B/page used): an array growing to the right
 *   - length list (keep length for malloc allocation greater than a page): an array growing to the left
 * As we have to growing arrays, we must add a check to avoid collision between them
 */

void mm_init(uintptr_t start_addr, uintptr_t end_addr)
{
    uintptr_t start_bmap = start_addr;
    uintptr_t start_heap = start_addr + 1024*1024;
    uintptr_t end_heap = end_addr - 1024*1024;

    // ensure that the heap start address is page aligned
    assert((start_heap & (OCAML_SOLO5_PAGESIZE-1)) == 0);

    bm_alloc = (bmap_allocator_t*)start_bmap;

    // round the number of pages to fit into a multiple of BPW
    size_t n_pages = (((end_heap-start_heap)/OCAML_SOLO5_PAGESIZE)/BPW)*BPW;
    assert((n_pages % BPW) == 0);
    end_heap = start_heap + n_pages*OCAML_SOLO5_PAGESIZE;

    bm_alloc->bmap_size = n_pages / BPW;
    bm_alloc->bmap = (uint64_t*)start_addr + sizeof(bmap_allocator_t);
    // start availables pages after the first 1MB
    bm_alloc->start_addr = start_heap;

    /*
     * All pages are initially free; set all bits in bmap[].
     */
    memset(bm_alloc->bmap, 0xff, bm_alloc->bmap_size * BPW);

    uintptr_t start_buddy = start_addr + \
      sizeof (bmap_allocator_t) + \
      bm_alloc->bmap_size * BPW;

    bu_alloc = (buddy_allocator_t*)start_buddy;
    nbu_alloc = 0;

    la_alloc = (keep_length_t*)(start_heap - sizeof(keep_length_t));
    nla_alloc = 0;

    printf("Ocaml-Solo5 allocator: version XXX\n");
    printf("Ocaml-Solo5:  reserved @ (%p - %p)\n", (void*)start_bmap, (void*)start_heap-1);
    DPRINTF("       bmap @ (%p - %p), %lu pages\n", (void*)start_bmap, (void*)start_buddy-1, n_pages);
    DPRINTF("      buddy @ (%p - %p)\n", (void*)start_buddy, (void*)start_heap-1);
    printf("Ocaml-Solo5:      heap @ (%p - %p)\n", (void*)start_heap, (void*)end_heap-1);
    printf("Ocaml-Solo5:     stack @ (%p - %p)\n", (void*)end_heap, (void*)end_addr);

}

/*********************** MMAP FAMILY FUNCTIONS ******************/

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

  size_t n_pages = len/OCAML_SOLO5_PAGESIZE;
  if (len%OCAML_SOLO5_PAGESIZE != 0) n_pages++;
  void *ptr = bmap_alloc(bm_alloc, n_pages);

  if (ptr == NULL) {
    // set errno
    DPRINTF("map failed for %lu.\n", len);
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
  if ((((uintptr_t)addr & (OCAML_SOLO5_PAGESIZE-1))) != 0) {
    DPRINTF("address %p (length %lu) is not aligned.\n", addr, length);
    errno = EINVAL;
    return -1;
  }

  size_t n_pages = length/OCAML_SOLO5_PAGESIZE;
  if (length%OCAML_SOLO5_PAGESIZE != 0) n_pages++;
  bmap_free(bm_alloc, addr, n_pages);
  return 0;
}

/*********************** MALLOC FAMILY FUNCTIONS ***************/

int posix_memalign(void **memptr, size_t alignment, size_t size)
{
    DPRINTF("request aligned size %lu (alignement constraint == %lu).\n", size, alignment);
    /* Although we can probably serve alignement greater than OCAML_SOLO5_PAGESIZE
     * it will raise complexity of the algorithm. So far Ocaml only uses 4096.
     */
    assert(alignment == OCAML_SOLO5_PAGESIZE);

    size_t n_pages = size/OCAML_SOLO5_PAGESIZE;
    if (size%OCAML_SOLO5_PAGESIZE != 0) n_pages++;

    void *ptr = bmap_alloc(bm_alloc, n_pages);
    if (ptr == NULL)
        return ENOMEM;
    DPRINTF("found at %p.\n", ptr);

    *memptr = ptr;
    push_length(&la_alloc, &nla_alloc, ptr, n_pages);

    /* ensure that the length array (left growing) doesn't collide with
     * the buddies (right growing)
     */
    assert((uintptr_t)la_alloc >= (uintptr_t)bu_alloc + nbu_alloc*sizeof(buddy_allocator_t));
    return 0;
}

void *malloc(size_t size)
{
    DPRINTF("request allocation for %lu.\n", size);

    if (size == 0)
    {
        return NULL;
    } else if (size<OCAML_SOLO5_PAGESIZE) {
	// with small request use the buddy allocator inside 1 page
	// reserve a new page if needed
        DPRINTF("small request %lu.\n", size);
		void* ptr = NULL;
		size_t count = 0;
		size_t n_blk = size/BUDDY_BLOCK_SIZE;
		if (size%BUDDY_BLOCK_SIZE != 0) n_blk++;

		// search for a buddy system with enough memory for the request
		while (!(count == nbu_alloc || ptr != NULL))
		{
            DPRINTF("try in buddy system %lu/%lu.\n", count, nbu_alloc);
            if (bu_alloc[count].max_available >= n_blk) ptr = buddy_alloc(&(bu_alloc[count]), n_blk);
            ++count;
		}

        DPRINTF("found a buddy system for it? %s.\n", (ptr != NULL)?"true":"false");
		if (ptr != NULL) // we found memory into this one
		{
			return ptr;
		} else { // count == nbu_alloc => we don't have a buddy system with enough memory, reserve a new page
			void* new_page = bmap_alloc(bm_alloc, 1);
            DPRINTF("allocate a new page at %p.\n", new_page);
			if (new_page == NULL)
				return NULL; // really no more memory available

            ++nbu_alloc;

            /* ensure that the length array (left growing) doesn't collide with
             * the buddies (right growing)
             */
            assert((uintptr_t)la_alloc >= (uintptr_t)bu_alloc + nbu_alloc*sizeof(buddy_allocator_t));

			buddy_init(bu_alloc, count, (uintptr_t)new_page);
            DPRINTF("init a buddy system for #%lu.\n", count);

			// we are sure to have memory with that new page
			return buddy_alloc(&(bu_alloc[count]), n_blk);
		}
	} else { // with large request use bmap allocator and keep the size in a list
        DPRINTF("large request %lu.\n", size);
        void* ptr = NULL;
        posix_memalign(&ptr, OCAML_SOLO5_PAGESIZE, size);
        return ptr;
	}
}

void free(void *ptr)
{
    DPRINTF("request free for %p.\n", ptr);
    if (ptr == NULL) return;

	size_t count = 0;
	/* search for a buddy system if the memory comes from here
	 * the second condition test if ptr match the address page
	 * at bu_alloc[count].start
	 */
	while (!(count == nbu_alloc || ((uintptr_t)ptr & (~(OCAML_SOLO5_PAGESIZE-1))) == bu_alloc[count].start))
	{
	    ++count;
    }

    if (count == nbu_alloc) // not found in the buddy system
    {
        DPRINTF("not found address %p in buddies.\n", ptr);
        uint16_t len = pop_length(la_alloc, nla_alloc, ptr);
        bmap_free(bm_alloc, ptr, len);
    } else { // found in the buddy system at 'count'
        DPRINTF("found address %p in buddy %d (%p).\n", ptr, count, bu_alloc[count].start);
    	buddy_free(&(bu_alloc[count]), ptr);
    }
}

void *calloc(size_t nmemb, size_t size)
{
    DPRINTF("request allocation for %lu*%lu.\n", nmemb, size);
    size_t total;
    if (__builtin_mul_overflow(nmemb, size, &total))
    {
        return NULL;
    }

    void * ptr = malloc(total);
    if (ptr == NULL)
        return NULL;

    DPRINTF("set %lu bytes at %p to 0s.\n", total, ptr);
    memset(ptr, 0, total);
    return ptr;
}

void *realloc(void *addr, size_t size)
{
    DPRINTF("request reallocation for %p %lu.\n", addr, size);
// naive implementation, we should find a way to avoid some copies
    void * ptr = malloc(size);
    if (ptr == NULL)
        return NULL;

    DPRINTF("copy %lu bytes from %p to %p.\n", size, addr, ptr);
    memcpy(ptr, addr, size);
    free(addr);
    return ptr;
}

/* returns the total memory currently in use, needed for mirage-solo5/mirage-xen */
size_t malloc_memory_usage(void)
{
	return memory_usage; // stub for the time being
}

/*********************** STUBS (to remove?) ********************/

struct mallinfo mallinfo(void)
{
	struct mallinfo m;
	memset(&m, 0, sizeof(struct mallinfo));
    // so far only uordblks is used (in mirage-solo5 and mirage-xen)
    m.uordblks = memory_usage;
	return m;
}

int malloc_trim(size_t pad)
{
    (void)pad; // unused argument
	return 0; // we won't ever return memory to the system :)
}
