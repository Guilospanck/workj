const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("constants.zig");
const logger = @import("logger.zig");
const config = @import("config.zig");

pub fn gitWorktreeAdd(allocator: std.mem.Allocator, directory: []const u8, branch: []const u8, branch_exists: bool) !void {
    var argv: []const []const u8 = undefined; // slice

    if (branch_exists) {
        argv = &.{ "git", "worktree", "add", directory, branch, "-q" };
    } else {
        argv = &.{ "git", "worktree", "add", directory, "-b", branch, config.get().main_branch, "-q" };
    }

    var cp = std.process.Child.init(argv, allocator);

    _ = try cp.spawnAndWait();
}

pub fn gitWorktreeRemove(allocator: std.mem.Allocator, branch: []const u8) !void {
    const argv = [_][]const u8{ "git", "worktree", "remove", branch };

    var cp = std.process.Child.init(&argv, allocator);
    _ = try cp.spawnAndWait();
}

pub fn gitBranchExists(allocator: std.mem.Allocator, branch: []const u8) !bool {
    const argv = [_][]const u8{ "git", "rev-parse", "--verify", branch };
    var cp = std.process.Child.init(&argv, allocator);

    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    const result = try cp.spawnAndWait();

    return result == .Exited and result.Exited == 0;
}

pub fn getOrCreateWorktreeDirectory(allocator: std.mem.Allocator, branch: []const u8) ![]const u8 {
    const project_root_directory = try getProjectRootLevelDirectory(allocator);
    defer allocator.free(project_root_directory);

    const project_name = try getProjectName(allocator);
    defer allocator.free(project_name);

    const worktree_directory = try std.fmt.allocPrint(allocator, "{s}/../{s}__worktrees/{s}", .{ utils.trimEnd(project_root_directory), utils.trimEnd(project_name), branch });

    const argv = [_][]const u8{ "mkdir", "-p", worktree_directory };

    var cp = std.process.Child.init(&argv, allocator);

    _ = try cp.spawnAndWait();

    return worktree_directory;
}

pub fn getProjectRootLevelDirectory(allocator: std.mem.Allocator) ![]const u8 {
    const argv = [_][]const u8{ "git", "rev-parse", "--show-toplevel" };
    const cwd = config.get().cwd;

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
        .cwd = cwd,
    });
    defer allocator.free(result.stderr);

    return result.stdout;
}

pub fn getProjectName(allocator: std.mem.Allocator) ![]const u8 {
    const argv = [_][]const u8{ "sh", "-c", "git remote get-url origin | xargs basename -s .git" };

    const cwd = config.get().cwd;
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &argv, .cwd = cwd });
    defer allocator.free(result.stderr);

    return result.stdout;
}

pub fn gitWorktreeExists(allocator: std.mem.Allocator, branch: []const u8) !bool {
    const arg_with_grep = try std.fmt.allocPrint(allocator, "git worktree list --porcelain | grep -q \"branch refs/heads/{s}\"", .{branch});
    defer allocator.free(arg_with_grep);

    const argv = [_][]const u8{ "sh", "-c", arg_with_grep };

    var cp = std.process.Child.init(&argv, allocator);

    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    const result = try cp.spawnAndWait();

    return result == .Exited and result.Exited == 0;
}
