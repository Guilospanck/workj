const std = @import("std");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const logger = @import("logger.zig");

const Self = @This();

layout: []u8,
main_branch: []u8,

var global: Self = undefined;
var initialised = false;

pub fn init(allocator: std.mem.Allocator, config_path_param: ?[]const u8) !void {
    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    // get workj config path
    var config_path: []const u8 = undefined;
    if (config_path_param == null) {
        const default_config_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_CONFIG_PATH });

        config_path = default_config_path;
    } else {
        config_path = config_path_param.?;
    }

    logger.debug("config_path: {s}", .{config_path});
    defer allocator.free(config_path);

    // Read config file into hashmap
    const file = try std.fs.cwd().openFile(config_path, .{ .mode = .read_only });
    defer file.close();

    const file_stat = try file.stat();
    const buffer = try file.readToEndAlloc(allocator, file_stat.size);
    defer allocator.free(buffer);

    var config_map = std.StringHashMap([]const u8).init(allocator);
    defer config_map.deinit();

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

    const default_layout = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_LAYOUT_CONFIG });
    defer allocator.free(default_layout);

    const default_main_branch = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_MAIN_BRANCH });
    defer allocator.free(default_main_branch);

    const layout = config_map.get("layout") orelse default_layout;
    const main_branch = config_map.get("main_branch") orelse default_main_branch;

    global = Self{ .layout = try utils.clone(allocator, layout), .main_branch = try utils.clone(allocator, main_branch) };

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
