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

const chunk = malloc_chunk;
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
)
{}
