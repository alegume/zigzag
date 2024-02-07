const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;
// const test_allocators = @import("test_allocators.zig");

pub fn main() !void {
    // try test_allocators.test_allocators();

}

fn increment(x: *u8) void {
    x.* += 1;
}

test "pointers" {
    var p: u8 = 1;
    increment(&p);
    try expect(p == 2);
}

test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}

fn total(vec: []const usize) usize {
    var acc: usize = 0;
    for (vec) |value| {
        acc += value;
    }
    return acc;
}

test "total slice" {
    const vec = [_]usize{ 100, 1000, 1000, 10, 1 };
    try expect(total(vec[0..3]) == 2100);
    try expect(total(vec[0..5]) == 2111);
    try expect(total(vec[0..]) == 2111);
}
