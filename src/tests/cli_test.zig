const std = @import("std");
const testing = std.testing;
const cli = @import("../cli.zig");
const command = @import("../commands.zig");

test {
    std.debug.print("\n\n====== Testing cli_test.zig ======\n", .{});
}

test "should have `add` command and its branch" {
    std.debug.print("\n>> Testing \"should have `add` command and its branch\" \n", .{});

    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "add";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Add,
        .config_path = null,
        .no_envs_copy = null,
        .other_args = null,
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", cmd, branch_name });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);
}

test "should have `remove` command and its branch" {
    std.debug.print("\n>> Testing \"should have `remove` command and its branch\" \n", .{});
    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "remove";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Remove,
        .config_path = null,
        .no_envs_copy = null,
        .other_args = null,
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", cmd, branch_name });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);
}

test "should have correct config file" {
    std.debug.print("\n>> Testing \"should have correct config file\" \n", .{});
    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "remove";
    const config_file = "./potato.cfg";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Remove,
        .config_path = config_file,
        .no_envs_copy = null,
        .other_args = null,
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", "-c", config_file, cmd, branch_name });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);

    const result2 = try cli.parseArgs(allocator, &.{ "workj", "--config-file", config_file, cmd, branch_name });
    defer result2.deinit(allocator);
    try testing.expectEqualDeep(expected, result2);
}

test "should have correct no_envs_copy flag set" {
    std.debug.print("\n>> Testing \"should have correct no_envs_copy flag set\" \n", .{});
    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "remove";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Remove,
        .config_path = null,
        .no_envs_copy = true,
        .other_args = null,
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", "-nec", cmd, branch_name });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);

    const result2 = try cli.parseArgs(allocator, &.{ "workj", "--no-envs-copy", cmd, branch_name });
    defer result2.deinit(allocator);
    try testing.expectEqualDeep(expected, result2);
}

test "should have correct other_args flags" {
    std.debug.print("\n>> Testing \"should have correct other_args flags\" \n", .{});
    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "remove";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Remove,
        .config_path = null,
        .no_envs_copy = null,
        .other_args = &.{ "--force", "--larry", "--potato" },
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", cmd, branch_name, "--force", "--larry", "--potato" });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);
}

test "should have all correct cli args" {
    std.debug.print("\n>> Testing \"should have all correct cli args\" \n", .{});
    const allocator = testing.allocator;

    const branch_name = "my-branch";
    const cmd = "add";
    const config_file = "./potato.cfg";

    const expected = cli.CliArgs{
        .branch_name = branch_name,
        .cmd = command.Command.Add,
        .config_path = config_file,
        .no_envs_copy = true,
        .other_args = &.{ "--force", "--larry", "--potato" },
    };

    const result = try cli.parseArgs(allocator, &.{ "workj", "-c", config_file, "-nec", cmd, branch_name, "--force", "--larry", "--potato" });
    defer result.deinit(allocator);
    try testing.expectEqualDeep(expected, result);
}

test "parseArgs - should display help" {
    std.debug.print("\n>> Testing \"parseArgs - should display help\" \n", .{});
    const allocator = testing.allocator;

    const result = cli.parseArgs(allocator, &.{ "workj", "-h" });
    try testing.expectError(cli.ArgsParseError.HelperRequired, result);

    const result2 = cli.parseArgs(allocator, &.{ "workj", "--help" });
    try testing.expectError(cli.ArgsParseError.HelperRequired, result2);
}

test "parseArgs - should error missing value when `--config-file` or `-c` arg is passed but missing value" {
    std.debug.print("\n>> Testing \"parseArgs - should error missing value when `--config-file` or `-c` arg is passed but missing value\" \n", .{});
    const allocator = testing.allocator;

    const result = cli.parseArgs(allocator, &.{ "workj", "-c" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result);

    const result2 = cli.parseArgs(allocator, &.{ "workj", "--config-file" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result2);
}

test "parseArgs - should error missing value when args are missing" {
    std.debug.print("\n>> Testing \"parseArgs - should error missing value when args are missing\" \n", .{});
    const allocator = testing.allocator;

    const result0 = cli.parseArgs(allocator, &.{"workj"});
    try testing.expectError(cli.ArgsParseError.MissingValue, result0);

    const result1 = cli.parseArgs(allocator, &.{ "workj", "add" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result1);

    const result2 = cli.parseArgs(allocator, &.{ "workj", "--config-file", "./potato" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result2);

    const result3 = cli.parseArgs(allocator, &.{ "workj", "asjfkasdjfklsadj" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result3);
}

test "parseArgs - should error unknown value when unknown optional/required parameters" {
    std.debug.print("\n>> Testing \"parseArgs - should error unknown value when unknown optional/required parameters\" \n", .{});
    const allocator = testing.allocator;

    // Unknown optional parameter
    const result = cli.parseArgs(allocator, &.{ "workj", "-potato" });
    try testing.expectError(cli.ArgsParseError.UnknownValue, result);

    // Unknown required parameter
    const result2 = cli.parseArgs(allocator, &.{ "workj", "potato", "larry" });
    try testing.expectError(cli.ArgsParseError.UnknownValue, result2);
}
