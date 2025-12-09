const std = @import("std");
const git = @import("git.zig");
const utils = @import("utils.zig");
const constants = @import("constants.zig");
const logger = @import("logger.zig");

const Command = enum {
    Add,
    Remove,

    fn fromString(s: []const u8) ?Command {
        if (std.mem.eql(u8, s, "add")) {
            return Command.Add;
        } else if (std.mem.eql(u8, s, "remove")) {
            return Command.Remove;
        } else {
            return null;
        }
    }
};

pub fn runCommand(allocator: std.mem.Allocator, branch: []const u8, cmd: []const u8) !?void {
    const parsedCommand = Command.fromString(cmd);

    if (parsedCommand == null) {
        return null;
    }

    switch (parsedCommand.?) {
        Command.Add => {
            try add(allocator, branch);
        },
        Command.Remove => {
            try remove(allocator, branch);
        },
    }
}

fn add(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const worktreeExists = try git.gitWorktreeExists(allocator, branch);
    if (worktreeExists) {
        logger.debug("Worktree already exists. Will not add it.", .{});
        // TODO: open zellij layouts on the already created worktree
        return;
    }

    const worktreeDirectory = try git.getOrCreateWorktreeDirectory(allocator, branch);
    defer allocator.free(worktreeDirectory);

    const branchExists = try git.gitBranchExists(allocator, branch);

    try git.gitWorktreeAdd(allocator, worktreeDirectory, branch, branchExists);
}

fn remove(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const worktreeExists = try git.gitWorktreeExists(allocator, branch);
    if (!worktreeExists) {
        logger.debug("Worktree does not exist. Nothing to remove.", .{});
        return;
    }

    try git.gitWorktreeRemove(allocator, branch);
}
