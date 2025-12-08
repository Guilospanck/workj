const std = @import("std");
const logger = @import("logger.zig");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const commands = @import("commands.zig");

const ArgsParseError = error{ MissingValue, UnknownValue };

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

    if (!try utils.isInGitRepo(allocator)) {
        std.debug.print("Must be used inside a git repository.\n", .{});
        return;
    }

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Remove program name
    _ = args.next();

    const cmd = try expectArg(&args, "<command>");
    const branch = try expectArg(&args, "<branch_name>");

    const response = try commands.parseCommand(allocator, branch, cmd);
    if (response == null) {
        std.debug.print("{s}", .{constants.USAGE});
    }
}

fn expectArg(iter: *std.process.ArgIterator, message: []const u8) ArgsParseError![]const u8 {
    const arg = iter.next() orelse {
        std.debug.print("Missing argument {s}.\n{s}\n", .{ message, constants.USAGE });
        return ArgsParseError.MissingValue;
    };

    return arg;
}
