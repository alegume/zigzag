const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const MatrixEntries = @import("matrix.zig").MatrixEntries;
const mm = @import("mm_files.zig");
// const assert = std.debug.assert;

pub fn CSR_Matrix(comptime T: type) type {
    return struct {
        v: ?[]T = null,             // Non zeros values
        col_index: []usize, // Column indices of values in v
        row_index: []usize, // Indices in v/rol_index where the rows starts
        nz_len: usize = 0,  // Non zeros elements
        m: usize = 0,       // number os rows/columns

        const Self = @This();
        pub fn init(m: usize, nz_len: usize, entries_type: MatrixEntries, allocator: std.mem.Allocator) Self {
            var v:?[]T = undefined;
            if (entries_type != MatrixEntries.pattern) {
                v = allocator.alloc(T, nz_len) catch unreachable;
            } else {
                v = null; 
            }   
            const col_index = allocator.alloc(usize, nz_len) catch unreachable;
            const row_index =allocator.alloc(usize, m + 1) catch unreachable;

            return .{
                .v          = v,
                .col_index  = col_index,
                .row_index  = row_index,
                .nz_len     = nz_len,
            };
        }
    };
}

pub fn matrixToCSR(comptime T:type, matrix: Matrix(T), allocator: std.mem.Allocator) CSR_Matrix(T) {
    var csr_matrix = CSR_Matrix(T).init(matrix.row, matrix.nz_len, matrix.entries_type, allocator);
    var count: usize = 0;

    csr_matrix.row_index[0] = 0; // Always
    csr_matrix.m = matrix.row;
    for (matrix.data, 1..) |row, i| {
        for (row, 0..) |data, j| {
            if (data) |val| {
                if (matrix.entries_type != MatrixEntries.pattern) {
                    csr_matrix.v.?[count] = val;
                }
                csr_matrix.col_index[count] = j;
                count += 1;
            }
        }
        csr_matrix.row_index[i] = count;
    }

    return csr_matrix;
}

// test "testing" {
//     // const file = "input/apache2.mtx";
//     // const file = "input/general/bcspwr01.mtx";
//     // const file = "input/big/nasa2910.mtx";
//     // const file = "input/big/Roget.mtx";
//     const file = "input/tests/b1_ss.mtx";
//     // const file = "input/tests/test2.mtx";

//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();

//     const entries_type = try mm.entriesType(file);
//     switch (entries_type) {
//         .float => {
//             const matrix = try mm.readAsMatrix(file, f64, allocator);
//             const csr_matrix = matrixToCSR(f64, matrix, allocator);
//             std.debug.print("{any}\n", .{csr_matrix});
//         },
//         else => {
//             const matrix = try mm.readAsMatrix(file, usize, allocator);
//             const csr_matrix = matrixToCSR(usize, matrix, allocator);
//             std.debug.print("{any}\n", .{csr_matrix});
//         },
//     }

//     // _ = try mm.readAsMatrix(file, f64);
// }

test "Testing CSR - test1.mtx" {
    const expect = std.testing.expect;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test1.mtx";
    try expect(try mm.entriesType(file) == MatrixEntries.int);

    const matrix = try mm.readAsMatrix(file, u8, allocator);
    const csr_matrix = matrixToCSR(u8, matrix, allocator);

    try expect(csr_matrix.nz_len == 4);
    try expect(csr_matrix.m == 4);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{5, 8, 3, 6}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 2, 1}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 1, 2, 3, 4}));
}

test "Testing CSR - test2.mtx" {
    const expect = std.testing.expect;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test2.mtx";
    try expect(try mm.entriesType(file) == MatrixEntries.int);

    const matrix = try mm.readAsMatrix(file, u8, allocator);
    const csr_matrix = matrixToCSR(u8, matrix, allocator);

    try expect(csr_matrix.nz_len == 8);
    try expect(csr_matrix.m == 6);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{10, 20, 30, 40, 50, 60, 70, 80}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 1, 3, 2, 3, 4, 5}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 2, 4, 7, 8, 8, 8}));
}

test "Testing CSR - b1_ss.mtx" {
    const expect = std.testing.expect;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/b1_ss.mtx";
    try expect(try mm.entriesType(file) == MatrixEntries.float);

    const matrix = try mm.readAsMatrix(file, f64, allocator);
    const csr_matrix = matrixToCSR(f64, matrix, allocator);

    try expect(csr_matrix.nz_len == 15);
    try expect(csr_matrix.m == 7);
    try expect(std.mem.eql(f64, csr_matrix.v.?, &[_]f64{1, 1, 1, -1, 0.45, -1, 0.1, -1, 0.45, -0.03599942, 1, -0.0176371, 1, -0.007721779, 1}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{1, 2, 3, 1, 4, 2, 5, 3, 6, 0, 4, 0, 5, 0, 6}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 3, 5, 7, 9, 11, 13, 15}));
}