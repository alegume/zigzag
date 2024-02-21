const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const mm = @import("mm_files.zig");
// const assert = std.debug.assert;
// const expect = std.testing.expect;

pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };




test "testing" {
    // const file = "input/apache2.mtx";
    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";
    // const file = "input/tests/b1_ss.mtx";
    const file = "input/tests/test3.mtx";

    // const et = try mm.entriesType(file);
    // std.debug.print("\n{any}\n", .{et});

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // const allocator = std.testing.allocator;
    const entries_type = try mm.entriesType(file);
    switch (entries_type) {
        .float => {
            var matrix = try mm.readAsMatrix(file, f64, allocator);
            matrix.print();
        },
        else => {
            var matrix = try mm.readAsMatrix(file, usize, allocator);
            // defer allocator.free(matrix);
            matrix.print();
        },
    }

    // _ = try mm.readAsMatrix(file, f64);
}