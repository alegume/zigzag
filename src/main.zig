const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const test_allocators = @import("test_allocators.zig");

pub fn main() !void {
    try test_allocators.test_allocators();
}
