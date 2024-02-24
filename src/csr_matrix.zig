const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const readAsMatrix = @import("matrix.zig").readAsMatrix;
const mm = @import("mm_files.zig");
const EntriesType = mm.EntriesType;
const assert = std.debug.assert;
const expect = std.testing.expect;

fn Element(comptime T: type) type {
    return struct {
        v: ?T,
        i: usize,
        j: usize
    };
}

pub fn CSR_Matrix(comptime T: type) type {
    return struct {
        v: ?[]T = null,     // Non zeros values
        col_index: []usize, // Column indices of values in v
        row_index: []usize, // Indices in v/rol_index where the rows starts
        nz_len: usize = 0,  // Non zeros elements
        m: usize = 0,       // number os rows/columns
        entries_type: EntriesType = undefined,
        max_degree:usize = 0,

        const Self = @This();
        pub fn init(m: usize, nz_len: usize, entries_type: EntriesType, allocator: std.mem.Allocator) Self {
            var v:?[]T = undefined;
            if (entries_type != EntriesType.pattern) {
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
                .m          = m
            };
        }
    };
}

pub fn csrFromFile(comptime T: type, path: []const u8, allocator:std.mem.Allocator) !CSR_Matrix(T) {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var lines_read: usize = 0;
    var n_lines: usize = 0;
    var m: usize = 0;
    var n: usize = 0;
    const csr = try allocator.create(CSR_Matrix(T));
    var el: Element(T) = undefined;
    var element_list = std.ArrayList(Element(T)).init(allocator);
    defer element_list.deinit();
    // const is_symmetric = mm.symmetry(path);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (m == 0) {
            // Ignore comments
            if (std.mem.startsWith(u8, line, "%"))
                continue;

            // first line of file => (rows:m, columns:n, entries)
            var it = std.mem.splitScalar(u8, line, ' ');
            m = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            if (m == 0) return mm.ReadingError.HeaderError;

            // Read n_lines (third number)
            n = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            n_lines = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;

            assert(m == n);
            assert(n_lines > 0);

            csr.* = CSR_Matrix(T).init(m, n_lines, EntriesType.int, allocator);
        } else {
            // Format => I1  J1  M(I1, J1)
            var it = std.mem.splitScalar(u8, line, ' ');
            // Parse Int in base 10
            el.i = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;
            el.j = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;

            const val = it.next() orelse null;
            // Patern Matrix (null and 1)
            if (val == null) {
                el.v = 1;
                // if (try is_symmetric) csr.data[j-1][i-1] = 1;
            } else { // Convert if not null
                switch (@typeInfo(T)) {
                    .Float => el.v = std.fmt.parseFloat(T, val.?) catch @panic("Not Float type!"),
                    .Int => el.v = std.fmt.parseInt(T, val.?, 10) catch @panic("Not Int type!"),
                    else => @panic("Error while reading value. Complex type???")
                }
            }
            // Add Element to element_list
            try element_list.append(el);
            lines_read += 1;
        }
    }
    assert(n_lines == lines_read);
    csr.entries_type = try mm.entriesType(path);

    // Sorting element_list
    const sorted_list = try element_list.toOwnedSlice();
    std.mem.sort(Element(T), sorted_list, {}, comptime ascByRowThenCol(T));

    //       Populate CSR 
    // row_index always starts whit 0 (first line)
    csr.row_index[0] = 0;
    var row_index:usize = 1;
    for (sorted_list, 0..) |e, i| {
        if (e.v) |val| 
            csr.v.?[i] = val;

        csr.col_index[i] = e.j - 1;

        if (e.i != row_index) { // New line
            csr.row_index[row_index] = i;

            const degree:usize = i - csr.row_index[row_index - 1];
            if (degree > csr.max_degree)
                csr.max_degree = degree;

            row_index = e.i; // New index
        }

    }
    csr.row_index[csr.m] = csr.nz_len;

    // In case it have more columns than rows
    if (row_index < m) {
        for (row_index..m) |i| {
            csr.row_index[i] = csr.nz_len;
        }
    }

    return csr.*;
}

test "csrFromFile" {
    const file = "input/tests/test2.mtx";
    // const file = "input/tests/b1_ss.mtx";
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const csr = try csrFromFile(u8, file, allocator);

    std.debug.print("\n\n{any}\n", .{csr});


}

test "Testing CSR from file - test1.mtx" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test1.mtx";
    try expect(try mm.entriesType(file) == EntriesType.int);

    const csr_matrix = try csrFromFile(u8, file, allocator);

    try expect(csr_matrix.nz_len == 4);
    try expect(csr_matrix.m == 4);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{5, 8, 3, 6}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 2, 1}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 1, 2, 3, 4}));
}

test "Testing CSR from file - test2.mtx" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test2.mtx";
    try expect(try mm.entriesType(file) == EntriesType.int);

    const csr_matrix = try csrFromFile(u8, file, allocator);

    try expect(csr_matrix.nz_len == 8);
    try expect(csr_matrix.m == 6);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{10, 20, 30, 40, 50, 60, 70, 80}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 1, 3, 2, 3, 4, 5}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 2, 4, 7, 8, 8, 8}));
}

test "Testing CSR from file - b1_ss.mtx" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/b1_ss.mtx";
    try expect(try mm.entriesType(file) == EntriesType.float);

    const csr_matrix = try csrFromFile(f64, file, allocator);

    try expect(csr_matrix.nz_len == 15);
    try expect(csr_matrix.m == 7);
    try expect(std.mem.eql(f64, csr_matrix.v.?, &[_]f64{1, 1, 1, -1, 0.45, -1, 0.1, -1, 0.45, -0.03599942, 1, -0.0176371, 1, -0.007721779, 1}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{1, 2, 3, 1, 4, 2, 5, 3, 6, 0, 4, 0, 5, 0, 6}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 3, 5, 7, 9, 11, 13, 15}));
}

// Sort generic list by row
fn ascByRowThenCol(comptime T: type) fn (void, Element(T), Element(T)) bool {
    const impl = struct {
        fn inner(context: void, a: Element(T), b: Element(T)) bool {
            _ = context;
            if (a.i < b.i) { // Compare based on "i"
                return true;
            } else if (a.i > b.i) {
                return false;
            } else { // If "i" is equal, compare based on "j"
                return a.j < b.j;
            }
        }
    };
    return impl.inner;
}


pub fn matrixToCSR(comptime T:type, matrix: Matrix(T), allocator: std.mem.Allocator) CSR_Matrix(T) {
    var csr_matrix = CSR_Matrix(T).init(matrix.row, matrix.nz_len, matrix.entries_type, allocator);
    var count: usize = 0;

    csr_matrix.row_index[0] = 0; // Always
    csr_matrix.m = matrix.row;
    for (matrix.data, 1..) |row, i| {
        for (row, 0..) |data, j| {
            if (data) |val| {
                if (matrix.entries_type != EntriesType.pattern) {
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
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test1.mtx";
    try expect(try mm.entriesType(file) == EntriesType.int);

    const matrix = try readAsMatrix(u8, file, allocator);
    const csr_matrix = matrixToCSR(u8, matrix, allocator);

    try expect(csr_matrix.nz_len == 4);
    try expect(csr_matrix.m == 4);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{5, 8, 3, 6}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 2, 1}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 1, 2, 3, 4}));
}

test "Testing CSR - test2.mtx" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/test2.mtx";
    try expect(try mm.entriesType(file) == EntriesType.int);

    const matrix = try readAsMatrix(u8, file, allocator);
    const csr_matrix = matrixToCSR(u8, matrix, allocator);

    try expect(csr_matrix.nz_len == 8);
    try expect(csr_matrix.m == 6);
    try expect(std.mem.eql(u8, csr_matrix.v.?, &[_]u8{10, 20, 30, 40, 50, 60, 70, 80}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{0, 1, 1, 3, 2, 3, 4, 5}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 2, 4, 7, 8, 8, 8}));
}

test "Testing CSR - b1_ss.mtx" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = "input/tests/b1_ss.mtx";
    try expect(try mm.entriesType(file) == EntriesType.float);

    const matrix = try readAsMatrix(f64, file, allocator);
    const csr_matrix = matrixToCSR(f64, matrix, allocator);

    try expect(csr_matrix.nz_len == 15);
    try expect(csr_matrix.m == 7);
    try expect(std.mem.eql(f64, csr_matrix.v.?, &[_]f64{1, 1, 1, -1, 0.45, -1, 0.1, -1, 0.45, -0.03599942, 1, -0.0176371, 1, -0.007721779, 1}));
    try expect(std.mem.eql(usize, csr_matrix.col_index, &[_]usize{1, 2, 3, 1, 4, 2, 5, 3, 6, 0, 4, 0, 5, 0, 6}));
    try expect(std.mem.eql(usize, csr_matrix.row_index, &[_]usize{0, 3, 5, 7, 9, 11, 13, 15}));
}