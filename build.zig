const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    if (builtin.zig_version.minor < 16) {
        @compileError("Zor only supports Zig 0.16+");
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Zor library
    const zor = b.addModule("zor", .{
        .root_source_file = b.path("src/zor.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Tests
    const tests = b.addTest(.{
        .name = "zor",
        .root_module = zor,
    });

    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run zor tests");
    test_step.dependOn(&run_tests.step);

    // Server example
    const server = b.addExecutable(.{
        .name = "server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/server/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    server.root_module.addImport("zor", zor);

    // Client example
    const client = b.addExecutable(.{
        .name = "client",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/client/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    client.root_module.addImport("zor", zor);

    // Build both examples.
    const example_step = b.step("example", "Build examples");
    example_step.dependOn(&server.step);
    example_step.dependOn(&client.step);

    b.installArtifact(server);
    b.installArtifact(client);
}
