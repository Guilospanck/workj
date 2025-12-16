const std = @import("std");
const builtin = @import("builtin");

const log = std.log;

pub fn err(comptime format: []const u8, args: anytype) void {
    if (!builtin.is_test) {
        log.err(format, args);
    }
}

pub fn warn(comptime format: []const u8, args: anytype) void {
    if (!builtin.is_test) {
        log.warn(format, args);
    }
}

pub fn info(comptime format: []const u8, args: anytype) void {
    if (!builtin.is_test) {
        log.info(format, args);
    }
}

pub fn debug(comptime format: []const u8, args: anytype) void {
    if (!builtin.is_test) {
        log.debug(format, args);
    }
}
