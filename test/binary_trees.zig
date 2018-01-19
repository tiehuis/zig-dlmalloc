const std = @import("std");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

const TreeNode = struct {
    l: ?&TreeNode,
    r: ?&TreeNode,

    pub fn new(a: &Allocator, l: ?&TreeNode, r: ?&TreeNode) -> &TreeNode {
        var node = a.create(TreeNode) catch unreachable;
        node.l = l;
        node.r = r;

        return node;
    }

    pub fn free(self: &TreeNode, a: &Allocator) {
        a.free(self);
    }
};

fn itemCheck(node: &TreeNode) -> usize {
    if (node.l) |left| {
        // either have both nodes or none
        return 1 + itemCheck(left) + itemCheck(??node.r);
    } else {
        return 1;
    }
}

fn bottomUpTree(a: &Allocator, depth: usize) -> &TreeNode {
    if (depth > 0) {
        return TreeNode.new(a, bottomUpTree(a, depth - 1), bottomUpTree(a, depth - 1));
    } else {
        return TreeNode.new(a, null, null);
    }
}

fn deleteTree(a: &Allocator, node: &TreeNode) {
    if (node.l) |left| {
        // either have both nodes or none
        deleteTree(a, left);
        deleteTree(a, ??node.r);
    }

    a.destroy(node);
}

pub fn testAllocator(comptime n: usize, allocator: &Allocator) -> %void {
    const min_depth: usize = 4;
    const max_depth: usize = n;
    const stretch_depth = max_depth + 1;

    const stretch_tree = bottomUpTree(allocator, stretch_depth);
    warn("  depth {}, check {}\n", stretch_depth, itemCheck(stretch_tree));
    deleteTree(allocator, stretch_tree);

    const long_lived_tree = bottomUpTree(allocator, max_depth);
    var depth = min_depth;
    while (depth <= max_depth) : (depth += 2) {
        var iterations = usize(std.math.pow(f32, 2, f32(max_depth - depth + min_depth)));
        var check: usize = 0;

        var i: usize = 1;
        while (i <= iterations) : (i += 1) {
            const temp_tree = bottomUpTree(allocator, depth);
            check += itemCheck(temp_tree);
            deleteTree(allocator, temp_tree);
        }

        warn("  {} trees of depth {}, check {}\n", iterations, depth, check);
    }

    warn("  long lived tree of depth {}, check {}\n", max_depth, itemCheck(long_lived_tree));
    deleteTree(allocator, long_lived_tree);
}
