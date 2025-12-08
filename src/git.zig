const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("constants.zig");

pub fn add(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const argv = [_][]const u8{ workjExec, "add", branch };

    try utils.spawnShell(allocator, argv[0..]);
}

pub fn remove(allocator: std.mem.Allocator, branch: []const u8) !void {
    const workjExec = try utils.getScriptAbsPath(allocator, constants.WORKJ_SCRIPT);
    defer allocator.free(workjExec);

    const argv = [_][]const u8{ workjExec, "remove", branch };

    try utils.spawnShell(allocator, argv[0..]);
}
