const std = @import("std");
const config = @import("../config.zig");
const utils = @import("../utils.zig");

pub fn makeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "mkdir", "-p", dir });
}

pub fn createBranch(allocator: std.mem.Allocator, branch: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "git", "branch", branch });
}

pub fn removeBranch(allocator: std.mem.Allocator, branch: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "git", "branch", "-D", branch });
}

pub fn removeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "rm", "-rf", dir });
}

pub fn runShellAtCwd(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, allocator);
    cp.cwd = config.get().cwd;
    _ = try cp.spawnAndWait();
}

pub fn setupGit(allocator: std.mem.Allocator, remote_origin: []const u8, main_branch: []const u8) !void {
    const cwd = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ config.get().cwd, remote_origin });
    defer allocator.free(cwd);

    // Make dir if doesn't exist
    try makeDir(allocator, cwd);

    // update config
    const layout = try utils.clone(allocator, config.get().layout);
    defer allocator.free(layout);
    try config.setConfig(allocator, .{
        .layout = layout,
        .main_branch = main_branch,
        .cwd = cwd,
        .no_envs_copy = false,
    });

    // init
    try runShellAtCwd(allocator, &.{ "git", "init", "-b", main_branch });

    // set identity
    try runShellAtCwd(allocator, &.{ "git", "config", "user.name", "Test User" });
    try runShellAtCwd(allocator, &.{ "git", "config", "user.email", "test@example.com" });

    // set dummy remote origin
    const dummy_remote_origin = try std.fmt.allocPrint(allocator, "https://git_test.com/{s}.git", .{remote_origin});
    defer allocator.free(dummy_remote_origin);

    try runShellAtCwd(allocator, &.{ "git", "remote", "add", "origin", dummy_remote_origin });

    // commit (needed to show correct branches)
    try runShellAtCwd(allocator, &.{ "git", "add", "." });
    try runShellAtCwd(allocator, &.{ "git", "commit", "--allow-empty", "-m", "initial" });
}

pub fn teardownGit(allocator: std.mem.Allocator) void {
    removeDir(allocator, config.get().cwd) catch {
        std.debug.print("Could not remove dir {s}", .{config.get().cwd});
    };
}
