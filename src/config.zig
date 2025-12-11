const std = @import("std");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const logger = @import("logger.zig");

const Self = @This();

layout: []u8,
main_branch: []u8,

var global: Self = undefined;
var initialised = false;

pub fn init(allocator: std.mem.Allocator) !void {
    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    var config_map = std.StringHashMap([]const u8).init(allocator);
    defer config_map.deinit();

    const default_layout = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_LAYOUT_CONFIG });
    defer allocator.free(default_layout);

    const default_main_branch = try std.fmt.allocPrint(allocator, "{s}", .{constants.DEFAULT_MAIN_BRANCH});
    defer allocator.free(default_main_branch);

    const fileExists = std.fs.cwd().openFile(constants.CONFIG_PATH, .{ .mode = .read_only });

    if (fileExists) |file| {
        defer file.close();

        const file_stat = try file.stat();
        const buffer = try file.readToEndAlloc(allocator, file_stat.size);
        defer allocator.free(buffer);

        var iter = std.mem.splitScalar(u8, buffer, '\n');
        while (iter.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0) continue;
            if (trimmed[0] == '#' or trimmed[0] == ';') continue;

            // find '='
            const eqIndex = std.mem.indexOf(u8, trimmed, "=") orelse continue;
            const key = std.mem.trim(u8, trimmed[0..eqIndex], " \t");
            const value = std.mem.trim(u8, trimmed[(eqIndex + 1)..], " \t");

            // store
            _ = try config_map.put(key, value);
        }
    } else |_| {
        logger.debug("Error opening file at {s}. Will use default configs.", .{constants.CONFIG_PATH});
    }

    const layout = config_map.get("layout") orelse default_layout;
    const main_branch = config_map.get("main_branch") orelse default_main_branch;

    global = Self{ .layout = try utils.clone(allocator, layout), .main_branch = try utils.clone(allocator, main_branch) };

    logger.debug("Global configs:\nlayout: {s}\nmain branch: {s}", .{ layout, main_branch });

    initialised = true;
}

pub fn deinit(allocator: std.mem.Allocator) void {
    if (!initialised) return;

    allocator.free(global.layout);
    allocator.free(global.main_branch);

    initialised = false;
}

pub fn get() *const Self {
    if (!initialised) @panic("Config not initialised.");

    return &global;
}
