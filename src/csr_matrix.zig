const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const MatrixEntries = @import("matrix.zig").MatrixEntries;
const mm = @import("mm_files.zig");
// const assert = std.debug.assert;
// const expect = std.testing.expect;

pub fn CSR_Matrix(comptime T: type) type {
    return struct {
        v: ?[]T,            // non zeros values
        col_index: []usize, // column indices of values in v
        row_index: []usize, // indices in v/rol_index where the rows starts
        nz_len: usize = 0,

        const Self = @This();
        pub fn init(nz_len: usize, entries_type: MatrixEntries, allocator: std.mem.Allocator) Self {
            var v:?[]T = undefined;
            if (entries_type != MatrixEntries.pattern) {
                v = allocator.alloc(T, nz_len) catch unreachable;
            } else {
                v = null;
            }
            const col_index = allocator.alloc(usize, nz_len) catch unreachable;
            const row_index =allocator.alloc(usize, nz_len + 1) catch unreachable;

            return .{
                .v = v,
                .col_index = col_index,
                .row_index = row_index,
                .nz_len = nz_len
            };
        }
    };
}

pub fn matrixToCSR(comptime T:type, matrix: Matrix(T), allocator: std.mem.Allocator) CSR_Matrix(T) {

    // var csr_matrix = try allocator.create(CSR_Matrix(T));
    const csr_matrix = CSR_Matrix(T).init(matrix.nz_len, matrix.entries_type, allocator);


    std.debug.print("\n{any}\n", .{csr_matrix});
    // std.debug.print("\n{any}\n", .{matrix});
    // std.debug.print("\n{any}\n", .{allocator});
    // for (matrix.data, 0..) |row, i| {
    //     for (row, 0..) |val, j| {
    //         // try expect(matrix.data[i][j] == val);
    //     }
    // }

    return csr_matrix;
}



test "testing" {
    // const file = "input/apache2.mtx";
    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";
    // const file = "input/tests/b1_ss.mtx";
    const file = "input/tests/test1.mtx";

    // const et = try mm.entriesType(file);
    // std.debug.print("\n{any}\n", .{et});

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const entries_type = try mm.entriesType(file);
    switch (entries_type) {
        .float => {
            const matrix = try mm.readAsMatrix(file, f64, allocator);
            const csr_matrix = matrixToCSR(f64, matrix, allocator);
            std.debug.print("{any}\n", .{csr_matrix});
        },
        else => {
            const matrix = try mm.readAsMatrix(file, usize, allocator);
            const csr_matrix = matrixToCSR(usize, matrix, allocator);
            std.debug.print("{any}\n", .{csr_matrix});
        },
    }

    // _ = try mm.readAsMatrix(file, f64);
}