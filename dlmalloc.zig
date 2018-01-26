// A port of dlmalloc for zig.
//
//-[Original]-----------------------------------------------------------------
//
//   This is a version (aka dlmalloc) of malloc/free/realloc written by
//   Doug Lea and released to the public domain, as explained at
//   http://creativecommons.org/publicdomain/zero/1.0/ Send questions,
//   comments, complaints, performance data, etc to dl@cs.oswego.edu
//
// * Version 2.8.6 Wed Aug 29 06:57:58 2012  Doug Lea
//    Note: There may be an updated version of this malloc obtainable at
//            ftp://gee.cs.oswego.edu/pub/misc/malloc.c
//          Check before installing!
//----------------------------------------------------------------------------

pub const malloc_chunk = extern struct {
    prev_foot: usize,       // size of previous chunk (if free)
    head: usize,            // size and inuse bits
    fd: ?&malloc_chunk,     // double links -- used only if free
    bk: ?&malloc_chunk,
};

const mchunk = malloc_chunk;
const mchunkptr = ?&malloc_chunk;
const sbinptr = ?&malloc_chunk;      // type of bins of chunks
const bindex_t = c_uint;
const binmap_t = c_uint;
const flag_t = c_uint;               // type of various bit flag sets

pub const malloc_tree_chunk = extern struct {
    // first four fields must be compatible with malloc_chunk
    prev_foot: usize,
    head: usize,
    fd: ?&malloc_tree_chunk,
    bk: ?&malloc_tree_chunk,

    child: [2]?&malloc_tree_chunk,
    parent: ?&malloc_tree_chunk,
    index: bindex_t,
};

const tchunk = malloc_tree_chunk;
const tchunkptr = ?&malloc_tree_chunk;
const tbinptr = ?&malloc_tree_chunk;     // type of bins of trees

pub const malloc_segment = extern struct {
    base: ?&u8,             // base address
    size: usize,            // allocated size
    next: ?&malloc_segment, // ptr to next segment
    sflags: flag_t          // mmap and extern flag
};

const msegment = malloc_segment;
const msegmentptr = ?&malloc_segment;

// Only used as a dependent
// TODO: Platform dependent.
const CHUNK_OVERHEAD = @sizeOf(usize);
const MALLOC_ALIGNMENT = 2 * @sizeOf(?&c_void); // This is exported incorrectly
const CHUNK_ALIGN_MASK = MALLOC_ALIGNMENT - 1;

// These are left as defines in dlmalloc.c so they can be at compile-time
// May not be necessary.
const NSMALLBINS = 32;
const NTREEBINS = 32;
const SMALLBIN_SHIFT = 3;
const SMALLBIN_WIDTH = 1 << SMALLBIN_SHIFT;
const TREEBIN_SHIFT = 8;
const MIN_LARGE_SIZE = 1 << TREEBIN_SHIFT;
const MAX_SMALL_SIZE = MIN_LARGE_SIZE - 1;
const MAX_SMALL_REQUEST = MAX_SMALL_SIZE - CHUNK_ALIGN_MASK - CHUNK_OVERHEAD;

pub const malloc_state = extern struct {
    smallmap: binmap_t,
    treemap: binmap_t,
    dvsize: usize,
    topsize: usize,
    least_addr: ?&u8,
    dv: mchunkptr,
    top: mchunkptr,
    trim_check: usize,
    release_checks: usize,
    magic: usize,
    // NOTE: Exporting these require a patched compiler. Incoming pull.
    smallbins: [(NSMALLBINS+1)*2]mchunkptr,
    treebins: [NTREEBINS]tbinptr,
    footprint: usize,
    max_footprint: usize,
    footprint_limit: usize,     // zero means no limit
    mflags: flag_t,
    seg: msegment,
    extp: ?&c_void,             // unused but available for externsions
    exts: usize,
};

extern const mstate = ?&malloc_state;

pub const malloc_params = extern struct {
    magic: usize,
    page_size: usize,
    granularity: usize,
    mmap_threshold: usize,
    trim_threshold: usize,
    default_mflags: flag_t,
};

// Workaround to export types to a header file.
export fn __type_export_workaround(
    a: malloc_chunk,
    b: malloc_tree_chunk,
    c: malloc_segment,
    d: malloc_state,
    e: malloc_params,
    f: [3]u8,
    g: [3][5]u8,
) void {}

// --------------------------------------------------------------

//#define is_aligned(A)       (((size_t)((A)) & (CHUNK_ALIGN_MASK)) == 0)
export fn is_aligned(a: ?&c_void) bool {
    const q = @ptrToInt(a);
    return q & CHUNK_ALIGN_MASK == 0;
}

//#define align_offset(A)\
// ((((size_t)(A) & CHUNK_ALIGN_MASK) == 0)? 0 :\
//  ((MALLOC_ALIGNMENT - ((size_t)(A) & CHUNK_ALIGN_MASK)) & CHUNK_ALIGN_MASK))
export fn align_offset(a: usize) usize {
    if (a & CHUNK_ALIGN_MASK == 0) {
        return 0;
    } else {
        return (MALLOC_ALIGNMENT - (a & CHUNK_ALIGN_MASK)) & CHUNK_ALIGN_MASK;
    }
}

// #define chunk2mem(p)        ((void*)((char*)(p)       + TWO_SIZE_T_SIZES))
export fn chunk2mem(p: ?&c_void) ?&c_void {
    const q = @ptrToInt(p);
    return @intToPtr(?&c_void, q + 2 * @sizeOf(usize));
}

//#define mem2chunk(mem)      ((mchunkptr)((char*)(mem) - TWO_SIZE_T_SIZES))
export fn mem2chunk(p: ?&c_void) ?&malloc_chunk {
    const q = @ptrToInt(p);
    return @intToPtr(?&malloc_chunk, q - 2 * @sizeOf(usize));
}

//#define align_as_chunk(A)   (mchunkptr)((A) + align_offset(chunk2mem(A)))
export fn align_as_chunk(p: ?&c_void) ?&malloc_chunk {
    const q = @ptrToInt(p);
    const aoff = @ptrToInt(chunk2mem(p));
    return @intToPtr(?&malloc_chunk, q + align_offset(aoff));
}

const MAX_REQUEST = (-MIN_CHUNK_SIZE << 2);
const MIN_REQUEST = (MIN_CHUNK_SIZE - CHUNK_OVERHEAD - 1);
const MIN_CHUNK_SIZE = (@sizeOf(malloc_chunk) + CHUNK_ALIGN_MASK) & ~usize(CHUNK_ALIGN_MASK);

const MMAP_CHUNK_OVERHEAD = 2 * @sizeOf(usize);
const MMAP_FOOT_PAD = 4 * @sizeOf(usize);

//#define pad_request(req) \
//   (((req) + CHUNK_OVERHEAD + CHUNK_ALIGN_MASK) & ~CHUNK_ALIGN_MASK)
export fn pad_request(a: usize) usize {
    return (a + CHUNK_OVERHEAD + CHUNK_ALIGN_MASK) & ~usize(CHUNK_ALIGN_MASK);
}

//#define request2size(req) \
//  (((req) < MIN_REQUEST)? MIN_CHUNK_SIZE : pad_request(req))
export fn request2size(a: usize) usize {
    if (a < MIN_REQUEST) {
        return MIN_CHUNK_SIZE;
    } else {
        return pad_request(a);
    }
}

// --- Bits

const PINUSE_BIT = usize(1);
const CINUSE_BIT = usize(2);
const FLAG4_BIT = usize(4);
const INUSE_BITS = PINUSE_BIT | CINUSE_BIT;
const FLAG_BITS = PINUSE_BIT|CINUSE_BIT|FLAG4_BIT;

const FENCEPOST_HEAD = INUSE_BITS | @sizeOf(usize);

// #define cinuse(p)           ((p)->head & CINUSE_BIT)
export fn cinuse(p: ?&malloc_chunk) bool {
    return (??p).head & CINUSE_BIT != 0;
}

// #define pinuse(p)           ((p)->head & PINUSE_BIT)
export fn pinuse(p: ?&malloc_chunk) bool {
    return (??p).head & PINUSE_BIT != 0;
}

// #define flag4inuse(p)       ((p)->head & FLAG4_BIT)
export fn flag4inuse(p: ?&malloc_chunk) bool {
    return (??p).head & FLAG4_BIT != 0;
}

// #define is_inuse(p)         (((p)->head & INUSE_BITS) != PINUSE_BIT)
export fn is_inuse(p: ?&malloc_chunk) bool {
    return (??p).head & INUSE_BITS != PINUSE_BIT;
}

// #define is_mmapped(p)       (((p)->head & INUSE_BITS) == 0)
export fn is_mmapped(p: ?&malloc_chunk) bool {
    return (??p).head & INUSE_BITS == 0;
}

// #define chunksize(p)        ((p)->head & ~(FLAG_BITS))
export fn chunksize(p: ?&malloc_chunk) usize {
    return (??p).head & ~(FLAG_BITS);
}

// #define clear_pinuse(p)     ((p)->head &= ~PINUSE_BIT)
export fn clear_pinuse(p: ?&malloc_chunk) void {
    (??p).head &= ~PINUSE_BIT;
}

// #define set_flag4(p)        ((p)->head |= FLAG4_BIT)
export fn set_flag4(p: ?&malloc_chunk) void {
    return (??p).head |= FLAG4_BIT;
}

// #define clear_flag4(p)      ((p)->head &= ~FLAG4_BIT)
export fn clear_flag4(p: ?&malloc_chunk) void {
    return (??p).head &= ~FLAG4_BIT;
}

// ---- Head foot

//#define chunk_plus_offset(p, s)  ((mchunkptr)(((char*)(p)) + (s)))
export fn chunk_plus_offset(p: ?&malloc_chunk, s: usize) ?&malloc_chunk {
    const q = @ptrToInt(p);
    return @intToPtr(?&malloc_chunk, q + s);
}

//#define chunk_minus_offset(p, s) ((mchunkptr)(((char*)(p)) - (s)))
export fn chunk_minus_offset(p: ?&malloc_chunk, s: usize) ?&malloc_chunk {
    const q = @ptrToInt(p);
    return @intToPtr(?&malloc_chunk, q - s);
}

//#define next_chunk(p) ((mchunkptr)( ((char*)(p)) + ((p)->head & ~FLAG_BITS)))
export fn next_chunk(p: ?&malloc_chunk) ?&malloc_chunk {
    const q = @ptrToInt(p);
    return @intToPtr(?&malloc_chunk, q + ((??p).head & ~FLAG_BITS));
}

//#define prev_chunk(p) ((mchunkptr)( ((char*)(p)) - ((p)->prev_foot) ))
export fn prev_chunk(p: ?&malloc_chunk) ?&malloc_chunk {
    const q = @ptrToInt(p);
    return @intToPtr(?&malloc_chunk, q - (??p).prev_foot);
}

//#define next_pinuse(p)  ((next_chunk(p)->head) & PINUSE_BIT)
export fn next_pinuse(p: ?&malloc_chunk) bool {
    return ((??next_chunk(p)).head & PINUSE_BIT) != 0;
}

//#define get_foot(p, s)  (((mchunkptr)((char*)(p) + (s)))->prev_foot)
export fn get_foot(p: ?&malloc_chunk, s: usize) usize {
    const q = @ptrToInt(p);
    const f = @intToPtr(?&malloc_chunk, q + s);
    return (??f).prev_foot;
}

//#define set_foot(p, s)  (((mchunkptr)((char*)(p) + (s)))->prev_foot = (s))
export fn set_foot(p: ?&malloc_chunk, s: usize) void {
    const q = @ptrToInt(p);
    const f = @intToPtr(?&malloc_chunk, q + s);
    (??f).prev_foot = s;
}

//#define set_size_and_pinuse_of_free_chunk(p, s)\
//  ((p)->head = (s|PINUSE_BIT), set_foot(p, s))
export fn set_size_and_pinuse_of_free_chunk(p: ?&malloc_chunk, s: usize) void {
    (??p).head = s | PINUSE_BIT;
    set_foot(p, s);
}

//#define set_free_with_pinuse(p, s, n)\
//  (clear_pinuse(n), set_size_and_pinuse_of_free_chunk(p, s))
export fn set_free_with_pinuse(p: ?&malloc_chunk, s: usize, n: ?&malloc_chunk) void {
    clear_pinuse(n);
    set_size_and_pinuse_of_free_chunk(p, s);
}

//#define overhead_for(p)\
// (is_mmapped(p)? MMAP_CHUNK_OVERHEAD : CHUNK_OVERHEAD)
export fn overhead_for(p: ?&malloc_chunk) usize {
    if (is_mmapped(p)) {
        return MMAP_CHUNK_OVERHEAD;
    } else {
        return CHUNK_OVERHEAD;
    }
}

