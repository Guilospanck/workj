const std = @import("std");
const utils = @import("utils.zig");
const logger = @import("logger.zig");
const config = @import("config.zig");

pub fn newTab(allocator: std.mem.Allocator, branch: []const u8, worktree_directory: []const u8) !void {
    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    const argv = [_][]const u8{ "zellij", "action", "new-tab", "--name", branch, "--cwd", worktree_directory, "--layout", config.get().layout };

    var cp = std.process.Child.init(&argv, allocator);

    _ = try cp.spawnAndWait();
}

pub fn closeTab(allocator: std.mem.Allocator, branch: []const u8) !void {
    const arg = try std.fmt.allocPrint(allocator, "zellij action go-to-tab-name {s} -c && zellij action close-tab", .{branch});
    defer allocator.free(arg);
    const argv = [_][]const u8{ "sh", "-c", arg };

    const result = try std.process.Child.run(.{ .argv = &argv, .allocator = allocator });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
}
