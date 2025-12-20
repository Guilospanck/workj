const std = @import("std");
const logger = @import("logger.zig");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const commands = @import("commands.zig");
const config = @import("config.zig");

const ArgsParseError = error{ MissingValue, UnknownValue, HelperRequired };

pub fn run() !void {
    // Allocator
    var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_alloc.allocator();
    defer {
        const deinit_result = debug_alloc.deinit();
        if (deinit_result != .ok) {
            logger.debug("DebugAllocator deinit reported error: {any}\n", .{deinit_result});
        }
    }

    if (!try utils.isInGitRepo(allocator)) {
        logger.err("Must be used inside a git repository.\n", .{});
        return;
    }

    if (!utils.isZellijInstalled(allocator)) {
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

    const cmd = expectArg(&args, "<command>") catch {
        logger.info("\n{s}", .{constants.USAGE});
        return;
    };
    const branch = expectArg(&args, "<branch_name>") catch {
        logger.info("\n{s}", .{constants.USAGE});
        return;
    };

    const response = try commands.runCommand(allocator, branch, cmd);
    if (response == null) {
        logger.info("\n{s}", .{constants.USAGE});
    }
}

fn expectArg(iter: *std.process.ArgIterator, message: []const u8) ArgsParseError![]const u8 {
    const arg = iter.next() orelse {
        logger.debug("Missing argument {s}.\n", .{message});
        return ArgsParseError.MissingValue;
    };

    if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
        // Not really an error, but works for our purposes of showing the usage.
        return ArgsParseError.HelperRequired;
    }

    return arg;
}
