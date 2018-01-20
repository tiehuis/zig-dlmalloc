const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) -> %void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("alloc_test", "alloc_test.zig");
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");

    const dlmalloc_c_obj = b.addCObject("dlmalloc.c.o", "../dlmalloc.c");
    exe.addObject(dlmalloc_c_obj);

    const dlmalloc_zig_obj = b.addObject("dlmalloc.zig.o", "../dlmalloc.zig");
    // TODO: Options aren't being added to command-line?
    const cflags = [][]const u8 {
        "-DUSE_DL_PREFIX",
    };
    dlmalloc_zig_obj.addCompileFlags(cflags);
    exe.addObject(dlmalloc_zig_obj);

    exe.setOutputPath("./alloc_test");

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
