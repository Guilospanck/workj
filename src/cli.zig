const std = @import("std");

const ArgsParseError = error{ MissingValue, UnknownValue };

pub fn run() !void {
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
    const programName = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "add")) {
            const branch = args.next() orelse return ArgsParseError.MissingValue;
            try add(branch);
        } else if (std.mem.eql(u8, arg, "remove")) {
            const branch = args.next() orelse return ArgsParseError.MissingValue;
            try remove(branch);
        } else {
            std.debug.print("Usage: {any} add/remove <branch_name>\n", .{programName});
            return ArgsParseError.UnknownValue;
        }
    }
}

fn add(branch: []const u8) !void {
    const alloc = std.heap.page_allocator;

    // Get current directory
    const cwd_dir = std.fs.cwd();
    const abs_path = try cwd_dir.realpathAlloc(alloc, ".");
    defer alloc.free(abs_path);

    // Build the workj.sh executable path
    const workjExec = try std.fmt.allocPrint(alloc, "{s}/scripts/workj.sh", .{abs_path});
    defer alloc.free(workjExec);

    const argv = [_][]const u8{ workjExec, "add", branch };

    try spawnShell(argv[0..]);
}

fn remove(branch: []const u8) !void {
    const argv = [_][]const u8{ "echo", branch };

    try spawnShell(argv[0..]);
}

fn spawnShell(argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, std.heap.page_allocator);

    try cp.spawn();
    const term = try cp.wait();

    switch (term) {
        .Signal => {
            std.debug.print("Command signal with code {any}\n", .{term});
        },
        .Stopped => {
            std.debug.print("Command stopped with code {any}\n", .{term});
        },
        .Unknown => {
            std.debug.print("Command failed with code {any}\n", .{term});
        },
        .Exited => {
            std.debug.print("Command exited with code {any}\n", .{term});
        },
    }
}
