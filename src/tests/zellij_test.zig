const std = @import("std");
const testing = std.testing;
const zellij = @import("../zellij.zig");
const git = @import("../git.zig");
const config = @import("../config.zig");
const test_utils = @import("test_utils.zig");

const BRANCH = "potato";

const QueryTabsCtx = struct {
    all_tab_names: std.StringHashMap(void),

    fn init(allocator: std.mem.Allocator) !QueryTabsCtx {
        const all_tab_names = try zellij.queryAllTabNames(allocator);
        return QueryTabsCtx{ .all_tab_names = all_tab_names };
    }

    fn deinit(self: *QueryTabsCtx, allocator: std.mem.Allocator) void {
        var it = self.all_tab_names.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        self.all_tab_names.deinit();
    }
};

test {
    std.debug.print("\n\n====== Testing zellij_test.zig ======\n", .{});
}

test "queryAllTabNames" {
    std.debug.print("\n>> Testing \"queryAllTabNames\" \n", .{});

    const allocator = testing.allocator;

    var query_tabs_ctx = try QueryTabsCtx.init(allocator);
    defer query_tabs_ctx.deinit(allocator);

    try testing.expect(query_tabs_ctx.all_tab_names.count() > 0);
}

test "tabs" {
    std.debug.print("\n>> Testing \"tabs\" \n", .{});

    const allocator = testing.allocator;

    // Initialise app-level configs
    try config.init(allocator);
    defer config.deinit(allocator);

    const directory = try git.getOrCreateWorktreeDirectory(allocator, BRANCH);
    defer allocator.free(directory);
    // Remove the created worktree directory
    defer test_utils.removeDir(allocator, directory) catch {
        std.debug.print("Could not remove dir {s}", .{directory});
    };

    // validate tabs before creating a new one
    var tabs_before_creation = try QueryTabsCtx.init(allocator);
    defer tabs_before_creation.deinit(allocator);

    try testing.expect(!tabs_before_creation.all_tab_names.contains(BRANCH));

    try zellij.newTab(allocator, BRANCH, directory);

    // validate tabs after creating a new one
    var tabs_after_creation = try QueryTabsCtx.init(allocator);
    defer tabs_after_creation.deinit(allocator);

    try testing.expect(tabs_after_creation.all_tab_names.contains(BRANCH));

    try zellij.closeTab(allocator, BRANCH);

    // validate tabs after closing
    var tabs_after_closing = try QueryTabsCtx.init(allocator);
    defer tabs_after_closing.deinit(allocator);

    try testing.expect(!tabs_after_closing.all_tab_names.contains(BRANCH));
}
