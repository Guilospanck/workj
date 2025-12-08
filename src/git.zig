const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("constants.zig");
const logger = @import("logger.zig");

pub fn add(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const worktreeExists = try gitWorktreeExists(allocator, branch);
    if (worktreeExists) {
        logger.debug("Worktree already exists. Will not add it.", .{});
        // TODO: open zellij layouts on the already created worktree
        return;
    }

    const worktreeDirectory = try getOrCreateWorktreeDirectory(allocator, branch);
    defer allocator.free(worktreeDirectory);

    const branchExists = try gitBranchExists(allocator, branch);

    try gitWorktreeAdd(allocator, worktreeDirectory, branch, branchExists);
}

pub fn remove(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const argv = [_][]const u8{ workjExec, "remove", branch };

    try utils.spawnShell(allocator, argv[0..]);
}

fn gitWorktreeAdd(allocator: std.mem.Allocator, directory: []const u8, branch: []const u8, branchExists: bool) !void {
    logger.debug("Directory: {s}\nBranch: {s}\nExists: {any}\n", .{ directory, branch, branchExists });

    var argv: []const []const u8 = undefined; // slice

    if (branchExists) {
        argv = &.{ "git", "worktree", "add", directory, branch, "-q" };
    } else {
        argv = &.{ "git", "worktree", "add", directory, "-b", branch, constants.MAIN_BRANCH, "-q" };
    }

    var cp = std.process.Child.init(argv, allocator);

    try cp.spawn();
    _ = try cp.wait();
}

fn gitBranchExists(allocator: std.mem.Allocator, branch: []const u8) !bool {
    const argv = [_][]const u8{ "git", "rev-parse", "--verify", branch };
    var cp = std.process.Child.init(&argv, allocator);

    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    try cp.spawn();
    const result = try cp.wait();

    return result == .Exited and result.Exited == 0;
}

fn getOrCreateWorktreeDirectory(allocator: std.mem.Allocator, branch: []const u8) ![]const u8 {
    const projectRootDirectory = try getProjectRootLevelDirectory(allocator);
    defer allocator.free(projectRootDirectory);

    const projectName = try getProjectName(allocator);
    defer allocator.free(projectName);

    const worktreeDirectory = try std.fmt.allocPrint(allocator, "{s}/../{s}__worktrees/{s}", .{ utils.trimEnd(projectRootDirectory), utils.trimEnd(projectName), branch });

    const argv = [_][]const u8{ "mkdir", "-p", worktreeDirectory };

    var cp = std.process.Child.init(&argv, allocator);

    try cp.spawn();
    _ = try cp.wait();

    return worktreeDirectory;
}

fn getProjectRootLevelDirectory(allocator: std.mem.Allocator) ![]const u8 {
    const argv = [_][]const u8{ "git", "rev-parse", "--show-toplevel" };

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &argv,
    });
    defer allocator.free(result.stderr);

    return result.stdout;
}

fn getProjectName(allocator: std.mem.Allocator) ![]const u8 {
    const argv = [_][]const u8{ "sh", "-c", "git remote get-url origin | xargs basename -s .git" };

    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &argv });
    defer allocator.free(result.stderr);

    return result.stdout;
}

fn gitWorktreeExists(allocator: std.mem.Allocator, branch: []const u8) !bool {
    const argWithGrep = try std.fmt.allocPrint(allocator, "git worktree list --porcelain | grep -q \"branch refs/heads/{s}\"", .{branch});
    defer allocator.free(argWithGrep);

    const argv = [_][]const u8{ "sh", "-c", argWithGrep };

    var cp = std.process.Child.init(&argv, allocator);

    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    try cp.spawn();

    const result = try cp.wait();

    return result == .Exited and result.Exited == 0;
}
