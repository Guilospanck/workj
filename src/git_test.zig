const std = @import("std");
const testing = std.testing;
const git = @import("git.zig");
const config = @import("config.zig");
const utils = @import("utils.zig");

const REMOTE_ORIGIN = "temp_test";
const MAIN_BRANCH = "temp-main";

const GitCtx = struct {
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !GitCtx {
        // Initialise app-level configs
        try config.init(allocator);
        try setupGit(allocator);

        return GitCtx{ .allocator = allocator };
    }

    fn deinit(self: GitCtx) void {
        defer config.deinit(self.allocator);
        teardownGit(self.allocator);
    }
};

test "gitWorktree" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator);
    defer ctx.deinit();

    // Branch exists
    {
        const branch: []const u8 = "branch-exists";
        const directory = try git.getOrCreateWorktreeDirectory(allocator, branch);
        defer allocator.free(directory);
        std.debug.print("DIRECTORY: {s}\n", .{directory});

        try createBranch(allocator, branch);
        const branch_exists = true;

        const worktree_does_not_exist = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(!worktree_does_not_exist);

        try git.gitWorktreeAdd(allocator, directory, branch, branch_exists);

        const worktree_exists = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(worktree_exists);

        const branch_exists_result = try git.gitBranchExists(allocator, branch);
        try testing.expect(branch_exists_result);

        // cleanup
        try git.gitWorktreeRemove(allocator, branch);
        try removeBranch(allocator, branch);

        const worktree_exists_after_delete = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(!worktree_exists_after_delete);

        const branch_exists_after_delete = try git.gitBranchExists(allocator, branch);
        try testing.expect(!branch_exists_after_delete);
    }

    // Branch does not exist
    {
        const branch: []const u8 = "branch-does-not-exist";
        const directory = try git.getOrCreateWorktreeDirectory(allocator, branch);
        defer allocator.free(directory);
        const branch_exists = false;

        const worktree_does_not_exist = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(!worktree_does_not_exist);

        try git.gitWorktreeAdd(allocator, directory, branch, branch_exists);

        const worktree_exists = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(worktree_exists);

        const branch_exists_result = try git.gitBranchExists(allocator, branch);
        try testing.expect(branch_exists_result);

        // cleanup
        try git.gitWorktreeRemove(allocator, branch);
        try removeBranch(allocator, branch);

        const worktree_exists_after_delete = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(!worktree_exists_after_delete);

        const branch_exists_after_delete = try git.gitBranchExists(allocator, branch);
        try testing.expect(!branch_exists_after_delete);
    }
}

test "getProjectRootLevelDirectory" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator);
    defer ctx.deinit();

    const root = try git.getProjectRootLevelDirectory(allocator);
    defer allocator.free(root);

    const ends_with_remote_origin = utils.endsWith(root, REMOTE_ORIGIN);

    try testing.expect(root.len > 0);
    try testing.expect(ends_with_remote_origin);
}

test "getProjectName" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator);
    defer ctx.deinit();

    const name = try git.getProjectName(allocator);
    defer allocator.free(name);
    try testing.expectEqualSlices(u8, REMOTE_ORIGIN, std.mem.trim(u8, name, "\n"));
}

test "gitBranchExists" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator);
    defer ctx.deinit();

    const exists = try git.gitBranchExists(allocator, MAIN_BRANCH);
    try testing.expect(exists);

    const notexists = try git.gitBranchExists(allocator, "this-branch-does-not-exist");
    try testing.expect(!notexists);
}

fn runShellAtCwd(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, allocator);
    cp.cwd = config.get().cwd;
    _ = try cp.spawnAndWait();
}

fn makeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "mkdir", "-p", dir });
}

fn removeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "rm", "-rf", dir });
}

fn createBranch(allocator: std.mem.Allocator, branch: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "git", "branch", branch });
}

fn removeBranch(allocator: std.mem.Allocator, branch: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "git", "branch", "-D", branch });
}

fn setupGit(allocator: std.mem.Allocator) !void {
    const cwd = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ config.get().cwd, REMOTE_ORIGIN });
    defer allocator.free(cwd);
    std.debug.print("CWD: {s}\n", .{cwd});

    // Make dir if doesn't exist
    try makeDir(allocator, cwd);

    // update config
    const layout = try utils.clone(allocator, config.get().layout);
    defer allocator.free(layout);
    try config.setConfig(allocator, .{
        .layout = layout,
        .main_branch = MAIN_BRANCH,
        .cwd = cwd,
    });

    // init
    try runShellAtCwd(allocator, &.{ "git", "init", "-b", MAIN_BRANCH });

    // set identity
    try runShellAtCwd(allocator, &.{ "git", "config", "user.name", "Test User" });
    try runShellAtCwd(allocator, &.{ "git", "config", "user.email", "test@example.com" });

    // set dummy remote origin
    const dummy_remote_origin = try std.fmt.allocPrint(allocator, "https://git_test.com/{s}.git", .{REMOTE_ORIGIN});
    defer allocator.free(dummy_remote_origin);

    try runShellAtCwd(allocator, &.{ "git", "remote", "add", "origin", dummy_remote_origin });

    // commit (needed to show correct branches)
    try runShellAtCwd(allocator, &.{ "git", "add", "." });
    try runShellAtCwd(allocator, &.{ "git", "commit", "--allow-empty", "-m", "initial" });
}

fn teardownGit(allocator: std.mem.Allocator) void {
    removeDir(allocator, config.get().cwd) catch {
        std.debug.print("Could not remove dir {s}", .{config.get().cwd});
    };
}
