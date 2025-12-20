const std = @import("std");
const logger = @import("logger.zig");

pub fn getAbsPath(allocator: std.mem.Allocator) ![]const u8 {
    const cwd_dir = std.fs.cwd();
    const abs_path = try cwd_dir.realpathAlloc(allocator, ".");

    return abs_path;
}

pub fn isInGitRepo(allocator: std.mem.Allocator) !bool {
    const argv = [_][]const u8{ "git", "rev-parse", "--is-inside-work-tree" };

    var cp = std.process.Child.init(&argv, allocator);

    // We don't need stdout, only exit status.
    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    const result = try cp.spawnAndWait();

    // exit code 0 means inside a Git repo
    return result == .Exited and result.Exited == 0;
}

pub fn isZellijInstalled(allocator: std.mem.Allocator) bool {
    const argv = [_][]const u8{ "sh", "-c", "command -v zellij" };

    var cp = std.process.Child.init(&argv, allocator);
    cp.stdout_behavior = .Ignore;
    cp.stderr_behavior = .Ignore;

    const result = cp.spawnAndWait() catch |err| {
        logger.debug("[ERROR] Could not check for zellij: {any}", .{err});
        return false;
    };

    return result == .Exited and result.Exited == 0;
}

pub fn trimEnd(s: []const u8) []const u8 {
    return std.mem.trimEnd(u8, s, "\n");
}

/// Allocates and returns a writable copy of the given `s` slice.
///
/// This function allocates a new buffer of length `s.len` using the
/// provided `allocator`, copies all bytes from `s` into it, and returns
/// the resulting `[]u8` slice pointing at the new memory.  The caller
/// is responsible for freeing the returned slice when it is no longer
/// needed using `allocator.free(...)`.
///
/// This is useful when you need to own a heap-allocated, mutable copy
/// of a `[]const u8` string or byte buffer.
///
/// - `allocator`: the allocator to use for memory allocation
/// - `s`: the source slice to clone
/// - returns: a new `[]u8` with the same contents as `s`
/// - errors: any allocation failure from `allocator.alloc(...)`
///
/// Example:
/// ```zig
/// const copy = try clone(allocator, someStr);
/// defer allocator.free(copy);
/// ```
///
/// `@memcpy` is used internally to copy the bytes.
pub fn clone(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    const out = try allocator.alloc(u8, s.len);
    @memcpy(out, s);

    return out;
}

pub fn getHomeDir(allocator: std.mem.Allocator) ![]u8 {
    const maybeHome = std.process.getEnvVarOwned(allocator, "HOME") catch |err| {
        if (err == std.process.GetEnvVarOwnedError.EnvironmentVariableNotFound) {
            // Fallback to Windows user profile
            return std.process.getEnvVarOwned(allocator, "USERPROFILE");
        } else {
            return err;
        }
    };
    return maybeHome;
}

pub fn endsWith(s: []const u8, with: []const u8) bool {
    if (s.len < with.len) return false;

    return std.mem.eql(u8, std.mem.trim(u8, s[s.len - with.len - 1 ..], "\n"), with);
}
