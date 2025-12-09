const std = @import("std");
const utils = @import("utils.zig");
const constants = @import("constants.zig");
const logger = @import("logger.zig");

// TODO: check if zellij is installed
// TODO: for the remove, use `go-to-tab-name` and `close-tab` zellij action functions
pub fn newTab(allocator: std.mem.Allocator, branch: []const u8, worktree_directory: []const u8) !void {
    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    const layout = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.LAYOUT_CONFIG });
    defer allocator.free(layout);

    logger.debug("Layout: {s}", .{layout});

    const argv = [_][]const u8{ "zellij", "action", "new-tab", "--name", branch, "--cwd", worktree_directory, "--layout", layout };

    var cp = std.process.Child.init(&argv, allocator);

    _ = try cp.spawnAndWait();
}
