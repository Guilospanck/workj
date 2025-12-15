const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Part of `build` process. This happens when `zig build`
    // and goes by default to zig-out/
    const exe = b.addExecutable(.{
        .name = "workj",
        .root_module = root_module,
    });
    b.installArtifact(exe);

    // Add a `run` step to execute the built exe.
    // This will be run with `zig build run`
    //
    // Creates a `Step` command from an `exe`.
    const run_cmd = b.addRunArtifact(exe);
    // Basically describes a `Step`
    const run = b.step("run", "Run the app");
    // Basically adds that description to the previous `Step` command
    run.dependOn(&run_cmd.step);
    // Allow running from the installation directory and not cache
    run_cmd.step.dependOn(b.getInstallStep());
    // allow passing args to the exe with `zig build run -- arg1 arg2 arg3 ...`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Add a `test` step.
    // This will be run with `zig build test`.
    //
    // Create the module where all the tests will be imported.
    const tests_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Creates the tests (like a `build` but for tests)
    const test_exe = b.addTest(.{ .root_module = tests_module });
    // Creates a `Step` command from an `exe`.
    const test_cmd = b.addRunArtifact(test_exe);
    // Basically describes a `Step`
    const test_step = b.step("test", "Run tests");
    // Basically adds that description to the previous `Step` command
    test_step.dependOn(&test_cmd.step);
}
