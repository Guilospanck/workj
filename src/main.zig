const cli = @import("cli.zig");
const logger = @import("logger.zig");

pub fn main() !void {
    cli.run() catch |err| {
        logger.err("Runtime error: {any}", .{err});
    };
}
