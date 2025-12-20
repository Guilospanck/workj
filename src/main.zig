const cli = @import("cli.zig");
const logger = @import("logger.zig");
const std = @import("std");

// INFO: this is how you can override the log level.
// pub const std_options: std.Options = .{
//     .log_level = .debug,
// };

pub fn main() !void {
    cli.run() catch |err| {
        logger.err("Runtime error: {any}", .{err});
    };
}
