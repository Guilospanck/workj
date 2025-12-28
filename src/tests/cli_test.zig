const std = @import("std");
const testing = std.testing;
const cli = @import("../cli.zig");

test "parseArgs - should display help" {
    const allocator = testing.allocator;

    const result = cli.parseArgs(allocator, &.{ "workj", "-h" });
    try testing.expectError(cli.ArgsParseError.HelperRequired, result);

    const result2 = cli.parseArgs(allocator, &.{ "workj", "--help" });
    try testing.expectError(cli.ArgsParseError.HelperRequired, result2);
}

test "parseArgs - should error missing value when `--config-file` or `-c` arg is passed but missing value" {
    const allocator = testing.allocator;

    const result = cli.parseArgs(allocator, &.{ "workj", "-c" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result);

    const result2 = cli.parseArgs(allocator, &.{ "workj", "--config-file" });
    try testing.expectError(cli.ArgsParseError.MissingValue, result2);
}

test "parseArgs - should error missing value when args are missing" {
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
    const allocator = testing.allocator;

    // Unknown optional parameter
    const result = cli.parseArgs(allocator, &.{ "workj", "-potato" });
    try testing.expectError(cli.ArgsParseError.UnknownValue, result);

    // Unknown required parameter
    const result2 = cli.parseArgs(allocator, &.{ "workj", "potato", "larry" });
    try testing.expectError(cli.ArgsParseError.UnknownValue, result2);
}
