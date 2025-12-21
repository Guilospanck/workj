const std = @import("std");
const testing = std.testing;
const git = @import("../git.zig");
const config = @import("../config.zig");
const utils = @import("../utils.zig");
const test_utils = @import("test_utils.zig");

const REMOTE_ORIGIN = "temp_test";
const MAIN_BRANCH = "temp-main";

const GitCtx = struct {
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, test_name: []const u8) !GitCtx {
        std.debug.print("\n>> Testing \"{s}\"\n", .{test_name});

        // Initialise app-level configs
        try config.init(allocator, null);
        try test_utils.setupGit(allocator, REMOTE_ORIGIN, MAIN_BRANCH);

        return GitCtx{ .allocator = allocator };
    }

    fn deinit(self: GitCtx) void {
        defer config.deinit(self.allocator);
        test_utils.teardownGit(self.allocator);
    }
};

test {
    std.debug.print("\n====== Testing git_test.zig ======\n", .{});
}

test "gitWorktree" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator, "gitWorktree");
    defer ctx.deinit();

    // Branch exists
    {
        const branch: []const u8 = "branch-exists";
        const directory = try git.getOrCreateWorktreeDirectory(allocator, branch);
        defer allocator.free(directory);
        std.debug.print("DIRECTORY: {s}\n", .{directory});

        try test_utils.createBranch(allocator, branch);
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
        try test_utils.removeBranch(allocator, branch);

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
        try test_utils.removeBranch(allocator, branch);

        const worktree_exists_after_delete = try git.gitWorktreeExists(allocator, branch);
        try testing.expect(!worktree_exists_after_delete);

        const branch_exists_after_delete = try git.gitBranchExists(allocator, branch);
        try testing.expect(!branch_exists_after_delete);
    }
}

test "getProjectRootLevelDirectory" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator, "getProjectRootLevelDirectory");
    defer ctx.deinit();

    const root = try git.getProjectRootLevelDirectory(allocator);
    defer allocator.free(root);

    const ends_with_remote_origin = utils.endsWith(root, REMOTE_ORIGIN);

    try testing.expect(root.len > 0);
    try testing.expect(ends_with_remote_origin);
}

test "getProjectName" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator, "getProjectName");
    defer ctx.deinit();

    const name = try git.getProjectName(allocator);
    defer allocator.free(name);
    try testing.expectEqualSlices(u8, REMOTE_ORIGIN, std.mem.trim(u8, name, "\n"));
}

test "gitBranchExists" {
    const allocator = testing.allocator;
    const ctx = try GitCtx.init(allocator, "gitBranchExists");
    defer ctx.deinit();

    const exists = try git.gitBranchExists(allocator, MAIN_BRANCH);
    try testing.expect(exists);

    const notexists = try git.gitBranchExists(allocator, "this-branch-does-not-exist");
    try testing.expect(!notexists);
}
