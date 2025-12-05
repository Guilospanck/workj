const std = @import("std");
const logger = @import("logger.zig");

const ArgsParseError = error{ MissingValue, UnknownValue };

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

const WORKJ_SCRIPT: []const u8 = "workj.sh";
const USAGE: []const u8 = "Usage: workj <command> <branch_name>\n\nAvailable commands: add, remove\n";

pub fn run() !void {
    // Allocator
    var debugAlloc: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debugAlloc.allocator();
    defer {
        const deinit_result = debugAlloc.deinit();
        if (deinit_result != .ok) {
            logger.err("DebugAllocator deinit reported error: {any}\n", .{deinit_result});
        }
    }

    if (!try isInGitRepo(allocator)) {
        std.debug.print("Must be used inside a git repository.\n", .{});
        return;
    }

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();

    const cmd = try expectArg(&args, "<command>");
    const branch = try expectArg(&args, "<branch_name>");

    const parsedCommand = Command.fromString(cmd);

    if (parsedCommand == null) {
        std.debug.print("{s}", .{USAGE});
        return;
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

fn isInGitRepo(allocator: std.mem.Allocator) !bool {
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

fn add(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try getScriptAbsPath(allocator, WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const argv = [_][]const u8{ workjExec, "add", branch };

    try spawnShell(allocator, argv[0..]);
}

fn remove(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try getScriptAbsPath(allocator, WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const argv = [_][]const u8{ workjExec, "remove", branch };

    try spawnShell(allocator, argv[0..]);
}

fn getScriptAbsPath(allocator: std.mem.Allocator, script: []const u8) ![]const u8 {
    // Get current absolute path
    const cwd_dir = std.fs.cwd();
    const abs_path = try cwd_dir.realpathAlloc(allocator, ".");
    defer allocator.free(abs_path);

    // Build the `script` executable path
    const workjExec = try std.fmt.allocPrint(allocator, "{s}/scripts/{s}", .{ abs_path, script });

    return workjExec;
}

fn spawnShell(allocator: std.mem.Allocator, argv: []const []const u8) !void {
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

fn expectArg(iter: *std.process.ArgIterator, message: []const u8) ArgsParseError![]const u8 {
    const arg = iter.next() orelse {
        std.debug.print("Missing argument {s}.\n{s}\n", .{ message, USAGE });
        return ArgsParseError.MissingValue;
    };

    return arg;
}
