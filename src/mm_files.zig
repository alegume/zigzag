// https://math.nist.gov/MatrixMarket/formats.html
const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const assert = std.debug.assert;
const expect = std.testing.expect;

pub const ReadingError = error{HeaderError};

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
    var real: bool = false;
    var integer: bool = false;
    var pattern: bool = false;
    const allocator = std.heap.page_allocator;
    var matrix = try allocator.create(Matrix(T));

    // header line (first line)
    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var hl = std.mem.splitBackwardsScalar(u8, first_line.?, ' ');
    if (std.mem.eql(u8, hl.next().?, "symmetric")) {
        symmetric = true;
    }
    const data_type:[]const u8 = hl.next() orelse " ";
    if (std.mem.eql(u8, data_type , "real")) {
        real = true;
    } else if (std.mem.eql(u8, data_type, "pattern")) {
        pattern = true;
    } else if (std.mem.eql(u8, data_type, "integer")) {
        integer = true;
    } else if (std.mem.eql(u8, data_type, "complex")) {
        std.debug.print("Complex type detected! Considering as pattern matrix.", .{});
        pattern = true;
    } else {
        std.debug.print("No type detected! Considering as pattern matrix.", .{});
        pattern = true;
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (m == 0) {
            // Ignore comments
            if (std.mem.startsWith(u8, line, "%"))
                continue;

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

            const val = it.next() orelse null;
            // Patern Matrix (null and 1)
            if (val == null) {
                matrix.data[i-1][j-1] = 1;
            } else { // Convert if not null
                switch (@typeInfo(T)) {
                    .Float => matrix.data[i-1][j-1] = std.fmt.parseFloat(T, val.?) catch @panic("Not Float type!"),
                    .Int => matrix.data[i-1][j-1] = std.fmt.parseInt(T, val.?, 10) catch @panic("Not Int type!"),
                    else => @panic("Error while reading value. Complex type???")
                }

            }
            lines_read += 1;
        }
    }
    assert(n_lines == lines_read);
    return matrix.*;
}

// test "reading HB file as matrix" {
//     const file1 = "input/tests/test1.mtx";
//     const matrix1 = try readAsMatrix(file1, u8);
//     var m1:[][]?u8 = undefined;
//     const allocator = std.heap.page_allocator;
//     m1 = allocator.alloc([]?u8, 4) catch unreachable;
//     for (0..4) |i|
//         m1[i] = allocator.alloc(?u8, 4) catch unreachable;
//     @memcpy(m1[0], ([_]?u8 {5, null, null, null})[0..]);
//     @memcpy(m1[1], ([_]?u8 {null, 8, null, null})[0..]);
//     @memcpy(m1[2], ([_]?u8 {null, null, 3, null})[0..]);
//     @memcpy(m1[3], ([_]?u8 {null, 6, null, null})[0..]);
//     try expect( @TypeOf(matrix1.data) == @TypeOf(m1));
//     for (m1, 0..) |row, i| 
//         for (row, 0..) |el, j| 
//             try expect(el == matrix1.data[i][j]);
// }