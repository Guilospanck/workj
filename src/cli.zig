const std = @import("std");

const ArgsParseError = error{ MissingValue, UnknownValue };

pub fn run() !void {
    std.debug.print("Hello from CLI\n", .{});

    // Allocator
    var debugAlloc: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debugAlloc.allocator();
    defer {
        const deinit_result = debugAlloc.deinit();
        if (deinit_result != .ok) {
            std.debug.print("DebugAllocator deinit reported error: {any}\n", .{deinit_result});
        }
    }

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Remove the program name
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "add")) {
            const branch = args.next() orelse return ArgsParseError.MissingValue;
            std.debug.print("(add) branch name is: {s}", .{branch});
        } else if (std.mem.eql(u8, arg, "remove")) {
            const branch = args.next() orelse return ArgsParseError.MissingValue;
            std.debug.print("(remove) branch name is: {s}", .{branch});
        } else {
            return ArgsParseError.UnknownValue;
        }
    }
}
