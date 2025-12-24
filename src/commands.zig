const std = @import("std");
const git = @import("git.zig");
const utils = @import("utils.zig");
const logger = @import("logger.zig");
const zellij = @import("zellij.zig");

pub const Command = enum {
    Add,
    Remove,

    pub fn fromString(s: []const u8) ?Command {
        if (std.mem.eql(u8, s, "add")) {
            return Command.Add;
        } else if (std.mem.eql(u8, s, "remove")) {
            return Command.Remove;
        } else {
            return null;
        }
    }
};

pub fn runCommand(allocator: std.mem.Allocator, branch: []const u8, cmd: Command, other_args: ?[]const []const u8) !?void {
    switch (cmd) {
        Command.Add => {
            try add(allocator, branch, other_args);
        },
        Command.Remove => {
            try remove(allocator, branch, other_args);
        },
    }
}

fn add(allocator: std.mem.Allocator, branch: []const u8, other_args: ?[]const []const u8) !void {
    const worktree_directory = try git.getOrCreateWorktreeDirectory(allocator, branch);
    defer allocator.free(worktree_directory);

    zellij.newTab(allocator, branch, worktree_directory) catch |err| {
        switch (err) {
            zellij.ZellijErrors.ZellijTabAlreadyExists => return,
            else => return err,
        }
    };

    const worktree_exists = try git.gitWorktreeExists(allocator, branch);
    if (worktree_exists) {
        logger.info("Worktree already exists. Will not add it.", .{});
        try zellij.newTab(allocator, branch, worktree_directory);

        return;
    }

    const branch_exists = try git.gitBranchExists(allocator, branch);

    try git.gitWorktreeAdd(allocator, worktree_directory, branch, branch_exists, other_args);
}

fn remove(allocator: std.mem.Allocator, branch: []const u8, other_args: ?[]const []const u8) !void {
    try zellij.closeTab(allocator, branch);

    const worktree_exists = try git.gitWorktreeExists(allocator, branch);
    if (!worktree_exists) {
        logger.info("Worktree does not exist. Nothing to remove.", .{});
        return;
    }

    try git.gitWorktreeRemove(allocator, branch, other_args);
}
