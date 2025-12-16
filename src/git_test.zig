const std = @import("std");
const testing = std.testing;
const git = @import("git.zig");
const config = @import("config.zig");

const REMOTE_ORIGIN = "temp_test";

test "getProjectRootLevelDirectory" {
    const allocator = testing.allocator;

    // Initialise app-level configs
    try config.init(allocator);
    defer config.deinit(allocator);

    try setupGit(allocator);
    defer teardownGit(allocator);

    const root = try git.getProjectRootLevelDirectory(allocator);
    defer allocator.free(root);

    try testing.expect(root.len > 0);
}

test "getProjectName" {
    const allocator = testing.allocator;

    // Initialise app-level configs
    try config.init(allocator);
    defer config.deinit(allocator);

    try setupGit(allocator);
    defer teardownGit(allocator);

    const name = try git.getProjectName(allocator);
    defer allocator.free(name);
    try testing.expectEqualSlices(u8, REMOTE_ORIGIN, std.mem.trim(u8, name, "\n"));
}

fn runShell(allocator: std.mem.Allocator, cwd: []const u8, argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, allocator);
    cp.cwd = cwd;
    _ = try cp.spawnAndWait();
}

fn makeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    const argv = [_][]const u8{ "mkdir", "-p", dir };
    var cp = std.process.Child.init(&argv, allocator);
    _ = try cp.spawnAndWait();
}

fn removeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    const argv = [_][]const u8{ "rm", "-rf", dir };
    var cp = std.process.Child.init(&argv, allocator);
    _ = try cp.spawnAndWait();
}

fn setupGit(allocator: std.mem.Allocator) !void {
    const cwd = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ config.get().cwd, REMOTE_ORIGIN });
    defer allocator.free(cwd);

    // Make dir if doesn't exist
    try makeDir(allocator, cwd);

    // update config
    try config.setCwd(allocator, cwd);

    // init
    try runShell(allocator, cwd, &.{ "git", "init" });

    // set identity
    try runShell(allocator, cwd, &.{ "git", "config", "user.name", "Test User" });
    try runShell(allocator, cwd, &.{ "git", "config", "user.email", "test@example.com" });

    // set dummy remote origin
    const dummy_remote_origin = try std.fmt.allocPrint(allocator, "https://git_test.com/{s}.git", .{REMOTE_ORIGIN});
    defer allocator.free(dummy_remote_origin);

    try runShell(allocator, cwd, &.{ "git", "remote", "add", "origin", dummy_remote_origin });

    // commit
    try runShell(allocator, cwd, &.{ "git", "add", "." });
    try runShell(allocator, cwd, &.{ "git", "commit", "--allow-empty", "-m", "initial" });
}

fn teardownGit(allocator: std.mem.Allocator) void {
    removeDir(allocator, config.get().cwd) catch {
        std.debug.print("Could not remove dir {s}", .{config.get().cwd});
    };
}
