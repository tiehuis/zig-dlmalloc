// zig build-exe alloc_test --library c

const std = @import("std");
const warn = std.debug.warn;
const tree = @import("binary_trees.zig");

const dlmalloc = @import("../dlmalloc_wrapper.zig");

// Time measuring
const c = @cImport({
    @cInclude("time.h");
});

pub fn timestamp() -> u64 {
    return u64(c.clock());
}

pub fn elapsedSeconds(diff: u64) -> f64 {
    return f64(diff * u64(c.CLOCKS_PER_SEC)) / 1000000;
}

// max depth of the tree
const n = 15;

pub fn testcase(comptime name: []const u8, allocator: &std.mem.Allocator) -> %void {
    warn("{} allocator ({})\n", name, usize(n));
    warn("\n");
    const s = timestamp();
    try tree.testAllocator(n, allocator);
    const e = timestamp();
    warn("\n");
    warn("  took {} seconds\n", elapsedSeconds(e - s));
    warn("\n\n");
}

pub fn main() -> %void {
    try testcase("c", std.heap.c_allocator);
    try testcase("dlmalloc", dlmalloc.dlmalloc_allocator);
}
