const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    if (builtin.zig_version.minor < 16) {
        @compileError("Zor only supports Zig 0.16+");
    }

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const zor = b.addModule("zor", .{
        .root_source_file = b.path("src/zor.zig"),
        .target = target,
        .optimize = mode,
    });

    const tests = b.addTest(.{
        .name = "zor",
        .root_module = zor,
    });

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run zor tests");
    test_step.dependOn(&run_tests.step);
}
