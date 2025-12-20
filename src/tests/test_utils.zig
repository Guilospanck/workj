const std = @import("std");
const config = @import("../config.zig");

pub fn removeDir(allocator: std.mem.Allocator, dir: []const u8) !void {
    try runShellAtCwd(allocator, &.{ "rm", "-rf", dir });
}

pub fn runShellAtCwd(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var cp = std.process.Child.init(argv, allocator);
    cp.cwd = config.get().cwd;
    _ = try cp.spawnAndWait();
}
