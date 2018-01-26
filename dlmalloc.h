#ifndef DLMALLOC_H
#define DLMALLOC_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
#define DLMALLOC_EXTERN_C extern "C"
#else
#define DLMALLOC_EXTERN_C
#endif

#if defined(_WIN32)
#define DLMALLOC_EXPORT DLMALLOC_EXTERN_C __declspec(dllimport)
#else
#define DLMALLOC_EXPORT DLMALLOC_EXTERN_C __attribute__((visibility ("default")))
#endif

struct malloc_chunk {
    uintptr_t prev_foot;
    uintptr_t head;
    struct malloc_chunk * fd;
    struct malloc_chunk * bk;
};

struct malloc_tree_chunk {
    uintptr_t prev_foot;
    uintptr_t head;
    struct malloc_tree_chunk * fd;
    struct malloc_tree_chunk * bk;
    struct malloc_tree_chunk * child[2];
    struct malloc_tree_chunk * parent;
    unsigned int index;
};

struct malloc_segment {
    uint8_t * base;
    uintptr_t size;
    struct malloc_segment * next;
    unsigned int sflags;
};

struct c_void;

struct malloc_state {
    unsigned int smallmap;
    unsigned int treemap;
    uintptr_t dvsize;
    uintptr_t topsize;
    uint8_t * least_addr;
    struct malloc_chunk * dv;
    struct malloc_chunk * top;
    uintptr_t trim_check;
    uintptr_t release_checks;
    uintptr_t magic;
    struct malloc_chunk * smallbins[66];
    struct malloc_tree_chunk * treebins[32];
    uintptr_t footprint;
    uintptr_t max_footprint;
    uintptr_t footprint_limit;
    unsigned int mflags;
    struct malloc_segment seg;
    void * extp;
    uintptr_t exts;
};

struct malloc_params {
    uintptr_t magic;
    uintptr_t page_size;
    uintptr_t granularity;
    uintptr_t mmap_threshold;
    uintptr_t trim_threshold;
    unsigned int default_mflags;
};

DLMALLOC_EXPORT void __type_export_workaround(struct malloc_chunk a, struct malloc_tree_chunk b, struct malloc_segment c, struct malloc_state d, struct malloc_params e, uint8_t f[], uint8_t g[]);
DLMALLOC_EXPORT bool is_aligned(void * a);
DLMALLOC_EXPORT uintptr_t align_offset(uintptr_t a);
DLMALLOC_EXPORT void * chunk2mem(void * p);
DLMALLOC_EXPORT struct malloc_chunk * mem2chunk(void * p);
DLMALLOC_EXPORT struct malloc_chunk * align_as_chunk(void * p);
DLMALLOC_EXPORT uintptr_t pad_request(uintptr_t a);
DLMALLOC_EXPORT uintptr_t request2size(uintptr_t a);
DLMALLOC_EXPORT bool cinuse(struct malloc_chunk * p);
DLMALLOC_EXPORT bool pinuse(struct malloc_chunk * p);
DLMALLOC_EXPORT bool flag4inuse(struct malloc_chunk * p);
DLMALLOC_EXPORT bool is_inuse(struct malloc_chunk * p);
DLMALLOC_EXPORT bool is_mmapped(struct malloc_chunk * p);
DLMALLOC_EXPORT uintptr_t chunksize(struct malloc_chunk * p);
DLMALLOC_EXPORT void clear_pinuse(struct malloc_chunk * p);
DLMALLOC_EXPORT void set_flag4(struct malloc_chunk * p);
DLMALLOC_EXPORT void clear_flag4(struct malloc_chunk * p);
DLMALLOC_EXPORT struct malloc_chunk * chunk_plus_offset(struct malloc_chunk * p, uintptr_t s);
DLMALLOC_EXPORT struct malloc_chunk * chunk_minus_offset(struct malloc_chunk * p, uintptr_t s);
DLMALLOC_EXPORT struct malloc_chunk * next_chunk(struct malloc_chunk * p);
DLMALLOC_EXPORT struct malloc_chunk * prev_chunk(struct malloc_chunk * p);
DLMALLOC_EXPORT bool next_pinuse(struct malloc_chunk * p);
DLMALLOC_EXPORT uintptr_t get_foot(struct malloc_chunk * p, uintptr_t s);
DLMALLOC_EXPORT void set_foot(struct malloc_chunk * p, uintptr_t s);
DLMALLOC_EXPORT void set_size_and_pinuse_of_free_chunk(struct malloc_chunk * p, uintptr_t s);
DLMALLOC_EXPORT void set_free_with_pinuse(struct malloc_chunk * p, uintptr_t s, struct malloc_chunk * n);
DLMALLOC_EXPORT uintptr_t overhead_for(struct malloc_chunk * p);
DLMALLOC_EXPORT struct malloc_tree_chunk * leftmost_child(struct malloc_tree_chunk * t);
DLMALLOC_EXPORT bool is_mmapped_segment(struct malloc_segment * s);
DLMALLOC_EXPORT bool is_extern_segment(struct malloc_segment * s);
DLMALLOC_EXPORT bool segment_holds(struct malloc_segment * s, struct malloc_chunk * a);
DLMALLOC_EXPORT bool should_trim(struct malloc_state * m, uintptr_t s);

#endif
