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

test "nested continue" {
    var count: usize = 0;
    for ([_]i32{ 1, 2, 3, 4, 5, 6, 7 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            break;
        }
    }
    try expect(count == 7);
}

fn hangeHasVal(begin: usize, end: usize, val: usize) bool {
    var i: usize = begin;
    return while (i <= end) : (i += 1) {
        if (i == val)
            break true;
    } else false;
}

test "hangeHasVal" {
    try expect(hangeHasVal(0, 10, 60) == false);
}

test "contains 6" {
    var index: ?usize = null;
    const vec = [_]f64{ 1, 2, 3, 4, 5.6, 6.9 };
    for (vec, 0..) |v, i| {
        if (v == 6) index = i;
    }
    try expect(index == undefined);
}

const Error = error{WrongPerson};
fn helloAleOrError(name: []const u8) !?bool {
    if (std.mem.eql(u8, name, "Ale")) {
        print("Hello, {s}\n", .{name});
        return true;
    } else if (std.mem.eql(u8, name, "ale")) {
        return false;
    }
    if (std.mem.eql(u8, name, "xandi")) {
        print("No harmonia do samba allowed, {s}\n", .{name});
        return null;
    }
    return Error.WrongPerson;
}

test "first error tpe" {
    const name = "xandi";

    // Se retornou true ou false
    if (helloAleOrError(name)) |not_xandi| {
        if (not_xandi) |ale| {
            if (ale) {
                print("Ale (Maiuscula)\n", .{});
            } else {
                print("ale (minuscula)\n", .{});
            }
        } else {
            print("Don't play axé on me. Sorry not sorry", .{});
        }
        // Se retornou Error
    } else |err| {
        std.debug.print("Error: {}\n", .{err});
    }
}

test "matrix" {
    var matrix:[2][2]usize = undefined;
    
    matrix = [_] [2]usize{
        [_]usize {1, 2},
        [_]usize {1, 2},
    };
    print("\n{any}\n", .{matrix});
}

test "null" {
    var x:?u8 = undefined;
    x = null;

    if (x) |_| {
        x = 11;
    } else {
        x = 0;
    }

    try expect(x == 0);
}