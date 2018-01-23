const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) -> %void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("alloc_test", "alloc_test.zig");
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");

    const dlmalloc_zig_obj = b.addObject("dlmalloc.zig.o", "../dlmalloc.zig");
    exe.addObject(dlmalloc_zig_obj);

    const dlmalloc_c_obj = b.addCObject("dlmalloc.c.o", "../dlmalloc.c");
    exe.addObject(dlmalloc_c_obj);
    // We require the zig-generated headers
    dlmalloc_c_obj.step.dependOn(&dlmalloc_zig_obj.step);

    exe.setOutputPath("./alloc_test");

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
