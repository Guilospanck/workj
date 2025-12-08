const std = @import("std");
const logger = @import("logger.zig");

pub fn getScriptAbsPath(allocator: std.mem.Allocator, script: []const u8) ![]const u8 {
    // Get current absolute path
    const cwd_dir = std.fs.cwd();
    const abs_path = try cwd_dir.realpathAlloc(allocator, ".");
    defer allocator.free(abs_path);

    // Build the `script` executable path
    const workjExec = try std.fmt.allocPrint(allocator, "{s}/scripts/{s}", .{ abs_path, script });

    return workjExec;
}

pub fn spawnShell(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, allocator);

    try cp.spawn();
    const term = try cp.wait();

    switch (term) {
        .Signal => |sig| {
            logger.debug("Terminated by signal {d}\n", .{sig});
        },
        .Stopped => |sig| {
            logger.debug("Stopped by signal {d}\n", .{sig});
        },
        .Unknown => |value| {
            logger.debug("Unknown termination {d}\n", .{value});
        },
        .Exited => |code| {
            logger.debug("Process exited with code {d}\n", .{code});
        },
    }
}

pub fn isInGitRepo(allocator: std.mem.Allocator) !bool {
    const argv = [_][]const u8{ "git", "rev-parse", "--is-inside-work-tree" };

    var cp = std.process.Child.init(&argv, allocator);

    // We don't need stdout, only exit status.
    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    try cp.spawn();

    const result = try cp.wait();

    // exit code 0 means inside a Git repo
    return result == .Exited and result.Exited == 0;
}
