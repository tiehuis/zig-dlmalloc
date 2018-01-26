// A Allocator wrapper over the exported functions of dlmalloc.

const std = @import("std");
const Allocator = std.mem.Allocator;

extern fn dlmalloc(n: usize) ?&c_void;
extern fn dlrealloc(p: ?&c_void, n: usize) ?&c_void;
extern fn dlfree(n: ?&c_void) void;

error OutOfMemory;

pub const dlmalloc_allocator = &dlmalloc_allocator_state;
var dlmalloc_allocator_state = Allocator {
    .allocFn = dlmallocWrapper,
    .reallocFn = dlreallocWrapper,
    .freeFn = dlfreeWrapper,
};

fn dlmallocWrapper(self: &Allocator, n: usize, alignment: u29) %[]u8 {
    return if (dlmalloc(n)) |buf|
        @ptrCast(&u8, buf)[0..n]
    else
        error.OutOfMemory;
}

fn dlreallocWrapper(self: &Allocator, old_mem: []u8, new_size: usize, alignment: u29) %[]u8 {
    const old_ptr = @ptrCast(&c_void, old_mem.ptr);
    if (dlrealloc(old_ptr, new_size)) |buf| {
        return @ptrCast(&u8, buf)[0..new_size];
    } else if (new_size <= old_mem.len) {
        return old_mem[0..new_size];
    } else {
        return error.OutOfMemory;
    }
}

fn dlfreeWrapper(self: &Allocator, old_mem: []u8) void {
    const old_ptr = @ptrCast(&c_void, old_mem.ptr);
    dlfree(old_ptr);
}
