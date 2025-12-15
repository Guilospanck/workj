const std = @import("std");
const testing = std.testing;
const git = @import("git.zig");

test "getProjectRootLevelDirectory" {
    const root = try git.getProjectRootLevelDirectory(testing.allocator);
    defer testing.allocator.free(root);
    try testing.expect(root.len > 0);
}

test "getProjectName" {
    const name = try git.getProjectName(testing.allocator);
    defer testing.allocator.free(name);
    try testing.expectEqualSlices(u8, "workj", std.mem.trim(u8, name, "\n"));
}
