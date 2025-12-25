const std = @import("std");
const logger = @import("logger.zig");
const constants = @import("constants.zig");
const utils = @import("utils.zig");
const commands = @import("commands.zig");
const config = @import("config.zig");

const ArgsParseError = error{ MissingValue, UnknownValue, HelperRequired, InternalError };

const CliArgs = struct {
    branch_name: []const u8 = "",
    cmd: commands.Command = commands.Command.Add,
    config_path: ?[]const u8 = null,
    other_args: ?[]const []const u8 = null, // this is what we can use to pass arguments to the underlying command.

    pub fn format(
        self: @This(),
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("CliArgs: {{ \n branch_name = {s},\n cmd = {any},\n config_path = {any},\n", .{ self.branch_name, self.cmd, self.config_path });
        if (self.other_args) |other_args| {
            for (other_args) |arg| {
                try writer.print("other_args = \"{s}\",\n", .{arg});
            }
        }
        try writer.print("}}\n", .{});
    }

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.branch_name);
        // Only free the memory if we actually allocated it
        if (self.config_path != null) {
            allocator.free(self.config_path.?);
        }
        if (self.other_args) |other_args| {
            for (other_args) |arg| {
                allocator.free(arg);
            }
            allocator.free(other_args);
        }
    }
};

pub fn run() !void {
    // Allocator
    var debug_alloc: std.heap.DebugAllocator(.{}) = .init;
    const allocator = debug_alloc.allocator();
    defer {
        const deinit_result = debug_alloc.deinit();
        if (deinit_result != .ok) {
            logger.debug("DebugAllocator deinit reported error: {any}\n", .{deinit_result});
        }
    }

    if (!try utils.isInGitRepo(allocator)) {
        logger.err("Must be used inside a git repository.\n", .{});
        return;
    }

    if (!utils.isZellijInstalled(allocator)) {
        logger.err("Zellij is not installed.\n", .{});
        return;
    }

    const args = parseArgs(allocator) catch return;
    defer args.deinit(allocator);
    logger.debug("{f}\n", .{args});

    // Initialise app-level configs
    try config.init(allocator, args.config_path);
    defer config.deinit(allocator);

    const response = try commands.runCommand(allocator, args.branch_name, args.cmd, args.other_args);
    if (response == null) {
        logger.info("\n{s}", .{constants.USAGE});
    }
}

fn parseArgs(allocator: std.mem.Allocator) ArgsParseError!CliArgs {
    const argv = std.process.argsAlloc(allocator) catch |err| {
        logger.err("{}", .{err});
        return ArgsParseError.InternalError;
    };
    defer std.process.argsFree(allocator, argv);

    var args = CliArgs{};
    // We need this here because when it errors, the caller will not run
    // the deinit on defer, therefore allocations made here would leak.
    errdefer args.deinit(allocator);

    var pos_int: usize = 1;

    // parse optional args
    while (pos_int < argv.len and argv[pos_int][0] == '-') {
        if (std.mem.eql(u8, argv[pos_int], "-h") or std.mem.eql(u8, argv[pos_int], "--help")) {
            displayUsage();
            return ArgsParseError.HelperRequired;
        } else if (std.mem.eql(u8, argv[pos_int], "-c") or std.mem.eql(u8, argv[pos_int], "--config-file")) {
            if (pos_int + 1 >= argv.len) {
                return ArgsParseError.MissingValue;
            }

            pos_int += 1;
            args.config_path = utils.clone(allocator, argv[pos_int]) catch |err| {
                logger.err("{}", .{err});
                return ArgsParseError.InternalError;
            };

            pos_int += 1;
        } else {
            displayUsage();
            return ArgsParseError.UnknownValue;
        }
    }

    if (pos_int >= argv.len) {
        displayUsage();
        return ArgsParseError.UnknownValue;
    }

    // parse positional arguments
    // parse command
    const cmd = argv[pos_int];
    pos_int += 1;
    const parsed_command = commands.Command.fromString(cmd);
    if (parsed_command == null or pos_int >= argv.len) {
        displayUsage();
        return ArgsParseError.UnknownValue;
    }

    args.cmd = parsed_command.?;

    // parse branch name
    args.branch_name = utils.clone(allocator, argv[pos_int]) catch |err| {
        logger.err("{}", .{err});
        return ArgsParseError.InternalError;
    };
    pos_int += 1;

    // No other args to pass to the underlying command
    if (pos_int == argv.len) {
        logger.debug("No additional args", .{});
        return args;
    }

    // get args that we would pass to the underlying command
    const other_args_slice = argv[pos_int..];
    var buffer = std.mem.Allocator.alloc(allocator, []const u8, other_args_slice.len) catch |err| {
        logger.err("Couldn't allocate memory for \"other_args\" buffer: {}", .{err});
        return ArgsParseError.InternalError;
    };
    errdefer allocator.free(buffer);

    for (other_args_slice, 0..) |arg, i| {
        buffer[i] = std.mem.Allocator.dupe(allocator, u8, arg) catch |err| {
            logger.err("Couldn't duplicate memory for arg \"{s}\" arg: {}", .{ arg, err });
            return ArgsParseError.InternalError;
        };
    }

    args.other_args = buffer;
    return args;
}

fn displayUsage() void {
    logger.info("\n{s}", .{constants.USAGE});
}
