// https://math.nist.gov/MatrixMarket/formats.html
const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;


pub const ReadingError = error{HeaderError};

// pub const Element = struct { v: ?f64, i: usize, j: usize };
pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };

pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]?T = undefined,
        row: usize,
        column: usize,
        symmetric: bool = false,

        const Self = @This(); // equivalent to Matrix(T)
        pub fn init(row: usize, column: usize, allocator: std.mem.Allocator) Self {
            const data = allocator.alloc([]?T, row) catch unreachable;
            var i: usize = 0;
            while (i < row) {
                data[i] = allocator.alloc(?T, column) catch unreachable;
                @memset(data[i], null);
                i += 1;
            }

            return .{
                .row = row,
                .column = column,
                .data = data,
            };
        }

        pub fn print(self: *Self) void {
            std.debug.print("\t Printing {}x{} matrix:\n", .{ self.row, self.column });
            for (self.data) |row| {
                for (row) |item| {
                    const char = item orelse 0;
                    std.debug.print("{any}\t", .{ char });
                }
                std.debug.print("\n", .{});
            }
        }
    };
}

pub fn readAsMatrix(path: []const u8, comptime T: type) !Matrix(T) {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var lines_read: usize = 0;
    var n_lines: usize = 0;
    var m: usize = 0;
    var n: usize = 0;
    var symmetric: bool = false;
    const allocator = std.heap.page_allocator;
    var matrix = try allocator.create(Matrix(T));

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (m == 0) {
            // header line
            var hl = std.mem.splitBackwardsScalar(u8, line, ' ');
            if (std.mem.eql(u8, hl.next().?, "symmetric")) {
                symmetric = true;
            }

            // Ignore comments
            if (std.mem.startsWith(u8, line, "%")) continue;

            // first line of file => (rows:m, columns:n, entries)
            var it = std.mem.splitScalar(u8, line, ' ');
            m = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            if (m == 0) return ReadingError.HeaderError;

            // Read n_lines (third number)
            n = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            n_lines = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;

            assert(m == n);
            assert(n_lines > 0);

            matrix.* = Matrix(T).init(m, n, allocator);
        } else {
            // Format => I1  J1  M(I1, J1)
            var it = std.mem.splitScalar(u8, line, ' ');
            const i = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;

            const j = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;

            matrix.data[i-1][j-1] = std.fmt.parseInt(T, it.next() orelse "1", 10) catch unreachable;

            lines_read += 1;
        }
    }
    assert(n_lines == lines_read);
    return matrix.*;
}

test "reading HB file as matrix" {
    // const file = "input/apache2.mtx";
    const file1 = "input/tests/test1.mtx";
    const matrix1 = try readAsMatrix(file1, u8);
    var m1:[][]?u8 = undefined;
    const allocator = std.heap.page_allocator;
    m1 = allocator.alloc([]?u8, 4) catch unreachable;
    for (0..4) |i|
        m1[i] = allocator.alloc(?u8, 4) catch unreachable;
    @memcpy(m1[0], ([_]?u8 {5, null, null, null})[0..]);
    @memcpy(m1[1], ([_]?u8 {null, 8, null, null})[0..]);
    @memcpy(m1[2], ([_]?u8 {null, null, 3, null})[0..]);
    @memcpy(m1[3], ([_]?u8 {null, 6, null, null})[0..]);
    try expect( @TypeOf(matrix1.data) == @TypeOf(m1));
    for (m1, 0..) |row, i| 
        for (row, 0..) |el, j| 
            try expect(el == matrix1.data[i][j]);


    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";

    // const file = "input/tests/test4-ipo.mtx";
    // var matrix = try readAsMatrix(file, u8);
    // matrix.print();
}

// Works for multidimensional arrays or slices
// fn printMatrix(mat: anytype) void {
//     const nrows = mat.len;
//     const ncols = mat[0].len;
//     std.debug.print("\n Printing {}x{} matrix: \n", .{ nrows, ncols });
//     for (mat) |row| {
//         for (row) |item| {
//             std.debug.print("{} ", .{ item });
//         }
//         std.debug.print("\n", .{});
//     }
// }
// test "printMatrix" {
//     const mat3x2 = [_][2]u32 {
//         [_]u32{ 1, 2 },
//         [_]u32{ 3, 4 },
//         [_]u32{ 5, 6 },
//     };
//     printMatrix(mat3x2);
// }


