const std = @import("std");
const logger = @import("logger.zig");

pub fn getAbsPath(allocator: std.mem.Allocator) ![]const u8 {
    const cwd_dir = std.fs.cwd();
    const abs_path = try cwd_dir.realpathAlloc(allocator, ".");

    return abs_path;
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

pub fn trimEnd(s: []const u8) []const u8 {
    return std.mem.trimEnd(u8, s, "\n");
}
