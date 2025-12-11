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

    const default_layout = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_LAYOUT_CONFIG });
    defer allocator.free(default_layout);

    const default_main_branch = try std.fmt.allocPrint(allocator, "{s}", .{constants.DEFAULT_MAIN_BRANCH});
    defer allocator.free(default_main_branch);

    const home_dir = try utils.getHomeDir(allocator);
    defer allocator.free(home_dir);

    const config_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ home_dir, constants.CONFIG_PATH });
    defer allocator.free(config_path);

    logger.debug("Checking config file at {s}", .{config_path});
    const fileExists = std.fs.openFileAbsolute(config_path, .{ .mode = .read_only });

    var layout = default_layout;
    var main_branch = default_main_branch;

    if (fileExists) |file| {
        logger.debug("Config at {s} exists. Reading it into list.", .{config_path});
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

            if (value.len == 0) continue;

            if (std.mem.eql(u8, key, "layout")) {
                layout = try utils.clone(allocator, value);
            } else if (std.mem.eql(u8, key, "main_branch")) {
                main_branch = try utils.clone(allocator, value);
            }
        }
    } else |err| {
        logger.debug("Error {any} opening file at {s}. Will use default configs.", .{ err, config_path });
    }

    global = Self{ .layout = try utils.clone(allocator, layout), .main_branch = try utils.clone(allocator, main_branch) };

    defer allocator.free(layout);
    defer allocator.free(main_branch);

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
