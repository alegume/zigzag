const std = @import("std");

pub const Element = struct { v: ?f64, i: usize, j: usize };

pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };

pub fn read(file: []const u8) ![]const Element {
    std.debug.print("{s}\n", .{file});
    const elements = [_]Element{ Element{ .v = 0.1, .i = 0, .j = 0 }, Element{ .v = 0.2, .i = 1, .j = 1 } };

    return &elements;
}

test "reading HB file" {}
