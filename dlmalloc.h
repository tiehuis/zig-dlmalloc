#ifndef DLMALLOC_H
#define DLMALLOC_H

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

#endif
