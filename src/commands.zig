const std = @import("std");
const git = @import("git.zig");

const Command = enum {
    Add,
    Remove,

    fn fromString(s: []const u8) ?Command {
        if (std.mem.eql(u8, s, "add")) {
            return Command.Add;
        } else if (std.mem.eql(u8, s, "remove")) {
            return Command.Remove;
        } else {
            return null;
        }
    }
};

pub fn parseCommand(allocator: std.mem.Allocator, branch: []const u8, cmd: []const u8) !?void {
    const parsedCommand = Command.fromString(cmd);

    if (parsedCommand == null) {
        return null;
    }

    switch (parsedCommand.?) {
        Command.Add => {
            try git.add(allocator, branch);
        },
        Command.Remove => {
            try git.remove(allocator, branch);
        },
    }
}
