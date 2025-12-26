const std = @import("std");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const logger = @import("logger.zig");

/// This is used as a singleton.
/// So the whole app can see the same.
///
const Self = @This();

layout: []const u8,
main_branch: []const u8,
cwd: []const u8,
no_envs_copy: bool,

var global: Self = undefined;
var initialised = false;

pub fn init(allocator: std.mem.Allocator, custom_config_file_path: ?[]const u8, cli_no_envs_copy: ?bool) !void {
    const abs_path = try utils.getAbsPath(allocator);
    defer allocator.free(abs_path);

    const home_dir = try utils.getHomeDir(allocator);
    defer allocator.free(home_dir);

    const home_dir_config_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ home_dir, constants.DEFAULT_CONFIG_PATH });
    defer allocator.free(home_dir_config_path);

    const config_path = custom_config_file_path orelse home_dir_config_path;

    logger.debug("Checking config file at {s}", .{config_path});
    const config_file_exists_at_dir = std.fs.openFileAbsolute(config_path, .{ .mode = .read_only });

    // default layout
    var layout = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ abs_path, constants.DEFAULT_LAYOUT_CONFIG });
    defer allocator.free(layout);

    // default main branch
    var main_branch = try std.fmt.allocPrint(allocator, "{s}", .{constants.DEFAULT_MAIN_BRANCH});
    defer allocator.free(main_branch);

    // CWD
    const cwd = std.process.getEnvVarOwned(allocator, "CWD") catch |err| blk: {
        if (err == std.process.GetEnvVarOwnedError.EnvironmentVariableNotFound) {
            break :blk try std.process.getCwdAlloc(allocator);
        } else {
            return err;
        }
    };
    defer allocator.free(cwd);

    var no_envs_copy = constants.DEFAULT_NO_ENVS_COPY;
    if (cli_no_envs_copy) |cli_no_envs| {
        no_envs_copy = cli_no_envs;
    }

    if (config_file_exists_at_dir) |file| {
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
                allocator.free(layout);
                layout = try utils.clone(allocator, value);
            } else if (std.mem.eql(u8, key, "main_branch")) {
                allocator.free(main_branch);
                main_branch = try utils.clone(allocator, value);
            } else if (std.mem.eql(u8, key, "no_envs_copy") and !no_envs_copy) {
                no_envs_copy = std.mem.eql(u8, value, "true");
            }
        }
    } else |err| {
        logger.debug("Error \"{any}\" opening file at \"{s}\". Will use default configs.", .{ err, config_path });
    }

    global = Self{ .layout = try utils.clone(allocator, layout), .main_branch = try utils.clone(allocator, main_branch), .cwd = try utils.clone(allocator, cwd), .no_envs_copy = no_envs_copy };

    logger.debug("Global configs:\nlayout: {s}\nmain branch: {s}\nCWD: {s}\nno_env_copy: {any}", .{ layout, main_branch, cwd, no_envs_copy });

    initialised = true;
}

pub fn deinit(allocator: std.mem.Allocator) void {
    if (!initialised) return;

    allocator.free(global.layout);
    allocator.free(global.main_branch);
    allocator.free(global.cwd);

    initialised = false;
}

pub fn get() *const Self {
    if (!initialised) @panic("Config not initialised.");

    return &global;
}

pub fn setConfig(allocator: std.mem.Allocator, values: Self) !void {
    if (!initialised) @panic("Config not initialised.");

    allocator.free(global.cwd);
    allocator.free(global.main_branch);
    allocator.free(global.layout);
    global.cwd = try utils.clone(allocator, values.cwd);
    global.main_branch = try utils.clone(allocator, values.main_branch);
    global.layout = try utils.clone(allocator, values.layout);
}
