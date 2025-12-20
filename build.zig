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
    const test_step = b.step("test", "Run unit tests");

    const run_unit_tests = b.addSystemCommand(&.{
        b.graph.zig_exe,
        "test",
        "src/test_runner.zig",
    });
    run_unit_tests.has_side_effects = true;

    test_step.dependOn(&run_unit_tests.step);
}
