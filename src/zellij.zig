const std = @import("std");
const utils = @import("utils.zig");
const logger = @import("logger.zig");
const config = @import("config.zig");

pub fn newTab(allocator: std.mem.Allocator, branch: []const u8, worktree_directory: []const u8) !void {
    var all_tab_names = try queryAllTabNames(allocator);
    defer {
        var it = all_tab_names.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        all_tab_names.deinit();
    }

    if (all_tab_names.contains(branch)) {
        logger.info("There is already a tab with the name \"{s}\", please select another.", .{branch});
        return;
    }

    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    const argv = [_][]const u8{ "zellij", "action", "new-tab", "--name", branch, "--cwd", worktree_directory, "--layout", config.get().layout };

    var cp = std.process.Child.init(&argv, allocator);

    _ = try cp.spawnAndWait();
}

pub fn closeTab(allocator: std.mem.Allocator, branch: []const u8) !void {
    var all_tab_names = try queryAllTabNames(allocator);
    defer {
        var it = all_tab_names.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        all_tab_names.deinit();
    }

    const numTabs = all_tab_names.count();
    if (numTabs == 0) {
        logger.info("No tabs found at all.", .{});
        return;
    }

    if (!all_tab_names.contains(branch)) {
        logger.info("No tab named \"{s}\" exists.", .{branch});
        return;
    }

    if (numTabs == 1) {
        logger.info("Only one tab open; won’t close it.", .{});
        return;
    }

    const arg = try std.fmt.allocPrint(allocator, "zellij action go-to-tab-name {s} -c && zellij action close-tab", .{branch});
    defer allocator.free(arg);
    const argv = [_][]const u8{ "sh", "-c", arg };

    const result = try std.process.Child.run(.{ .argv = &argv, .allocator = allocator });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
}

fn queryAllTabNames(allocator: std.mem.Allocator) !std.StringHashMap(void) {
    var map = std.StringHashMap(void).init(allocator);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "zellij",
            "action",
            "query-tab-names",
        },
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    var it = std.mem.splitScalar(u8, result.stdout, '\n');
    while (it.next()) |line| {
        if (line.len == 0) continue;

        const key = try allocator.dupe(u8, line);
        try map.put(key, {});
    }

    return map;
}
