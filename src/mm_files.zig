// https://math.nist.gov/MatrixMarket/formats.html
const std = @import("std");
const assert = std.debug.assert;

pub const Element = struct { v: ?f64, i: usize, j: usize };

pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };

pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]T = undefined,
        row: usize,
        column: usize,
        symmetric: bool = false,

        const Self = @This(); // equivalent to Matrix(T)
        pub fn init(row: usize, column: usize, allocator: std.mem.Allocator) Self {
            const data = allocator.alloc([]T, row) catch unreachable;
            var i: usize = 0;
            while (i < row) {
                data[i] = allocator.alloc(T, column) catch unreachable;
                @memset(data[i], 0);
                i += 1;
            }

            return .{
                .row = row,
                .column = column,
                .data = data,
            };
        }
    };
}

pub const ReadingError = error{HeaderError};

pub fn read(path: []const u8, comptime T: type) ![]const Element {
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
                std.debug.print("\nTRUEEEE\n", .{});
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
            var it = std.mem.splitScalar(u8, line, ' ');
            const i = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            const j = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            matrix.data[i-1][j-1] = 9;
            lines_read += 1;
            // Format => I1  J1  M(I1, J1)

        }

    }
    std.debug.print("{any}\n", .{matrix});
    assert(n_lines == lines_read);
    
    // printMatrix(matrix.matrix);
    // std.debug.print("matrix size:{any}\n", .{m});
    // std.debug.print("n_lines:{any}\n", .{n_lines});
    // std.debug.print("lines_read:{any}\n", .{lines_read});
    // std.debug.print("lines: {}\n", .{lines_read});






    const elements = [_]Element{ Element{ .v = 0.1, .i = 0, .j = 0 }, Element{ .v = 0.2, .i = 1, .j = 1 } };

    // read first line (size x )

    // create array


    return &elements;
}

test "reading HB file" {
    // const file = "input/apache2.mtx";
    const file = "input/tests/test1.mtx";
    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";

    _ = try read(file, u8);
}

// Works for multidimensional arrays or slices
fn printMatrix(mat: anytype) void {
    const nrows = mat.len;
    const ncols = mat[0].len;
    std.debug.print("\n Printing {}x{} matrix: \n", .{ nrows, ncols });
    for (mat) |row| {
        for (row) |item| {
            std.debug.print("{} ", .{ item });
        }
        std.debug.print("\n", .{});
    }
}

// test "printMatrix" {
//     const mat3x2 = [_][2]u32 {
//         [_]u32{ 1, 2 },
//         [_]u32{ 3, 4 },
//         [_]u32{ 5, 6 },
//     };
//     printMatrix(mat3x2);
// }


