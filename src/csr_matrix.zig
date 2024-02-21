const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const MatrixEntries = @import("matrix.zig").MatrixEntries;
const mm = @import("mm_files.zig");
// const assert = std.debug.assert;
// const expect = std.testing.expect;

pub fn CSR_Matrix(comptime T: type) type {
    return struct {
        v: []T,            // non zeros values
        col_index: []usize, // column indices of values in v
        row_index: []usize, // indices in v/rol_index where the rows starts
        nz_len: usize = 0,

        const Self = @This();
        pub fn init(m: usize, nz_len: usize, entries_type: MatrixEntries, allocator: std.mem.Allocator) Self {
            var v:[]T = undefined;
            if (entries_type != MatrixEntries.pattern) {
                v = allocator.alloc(T, nz_len) catch unreachable;
            } else { // Fill it with garbage
                v = allocator.alloc(T, 1) catch unreachable;
                v[0] = 0; 
            }   
            const col_index = allocator.alloc(usize, nz_len) catch unreachable;
            const row_index =allocator.alloc(usize, m + 1) catch unreachable;

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
    var csr_matrix = CSR_Matrix(T).init(matrix.row, matrix.nz_len, matrix.entries_type, allocator);
    var count: usize = 0;

    csr_matrix.row_index[0] = 0; // Always
    for (matrix.data, 1..) |row, i| {
        for (row, 0..) |data, j| {
            if (data) |val| {
                if (matrix.entries_type != MatrixEntries.pattern) {
                    csr_matrix.v[count] = val;
                }
                csr_matrix.col_index[count] = j;
                count += 1;
            }
        }
        csr_matrix.row_index[i] = count;
    }

    return csr_matrix;
}


test "testing" {
    // const file = "input/apache2.mtx";
    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";
    const file = "input/tests/b1_ss.mtx";
    // const file = "input/tests/test2.mtx";

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