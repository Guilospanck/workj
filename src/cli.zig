const std = @import("std");
const logger = @import("logger.zig");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const commands = @import("commands.zig");
const config = @import("config.zig");

const ArgsParseError = error{ MissingValue, UnknownValue };

pub fn run() !void {
    // Allocator
    var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_alloc.allocator();
    defer {
        const deinit_result = debug_alloc.deinit();
        if (deinit_result != .ok) {
            logger.err("DebugAllocator deinit reported error: {any}\n", .{deinit_result});
        }
    }

    if (!try utils.isInGitRepo(allocator)) {
        logger.err("Must be used inside a git repository.\n", .{});
        return;
    }

    if (!try utils.isZellijInstalled(allocator)) {
        logger.err("Zellij is not installed.\n", .{});
        return;
    }

    // Initialise app-level configs
    try config.init(allocator);
    defer config.deinit(allocator);

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Remove program name
    _ = args.next();

    const cmd = try expectArg(&args, "<command>");
    const branch = try expectArg(&args, "<branch_name>");

    const response = try commands.runCommand(allocator, branch, cmd);
    if (response == null) {
        logger.info("{s}", .{constants.USAGE});
    }
}

fn expectArg(iter: *std.process.ArgIterator, message: []const u8) ArgsParseError![]const u8 {
    const arg = iter.next() orelse {
        logger.err("Missing argument {s}.\n{s}\n", .{ message, constants.USAGE });
        return ArgsParseError.MissingValue;
    };

    return arg;
}
