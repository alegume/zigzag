// https://math.nist.gov/MatrixMarket/formats.html
const std = @import("std");
const assert = std.debug.assert;

pub const Element = struct { v: ?f64, i: usize, j: usize };

pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };

pub const ReadingError = error{HeaderError};

pub fn read(path: []const u8) ![]const Element {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var lines_read: usize = 0;
    var n_lines: usize = 0;
    var m: ?usize = null;
    var n: ?usize = null;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (m == null) {
            // Ignore comments
            if (std.mem.startsWith(u8, line, "%")) continue;
            // first line of file => (rows:m, columns:n, entries)
            var it = std.mem.split(u8, line, " ");
            m = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            if (m == 0) return ReadingError.HeaderError;
            // Read n_lines (third number)
            n = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            n_lines = std.fmt.parseInt(usize, it.next() orelse "0", 10) catch 0;
            assert(m == n);
            assert(n_lines > 0);
        } else {
            lines_read += 1;
            // std.debug.print("{s}\n", .{line});
            // Format => I1  J1  M(I1, J1)

        }

    }
    assert(n_lines == lines_read);
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
    // const file = "input/tests/test2.mtx";
    // const file = "input/big/nasa2910.mtx";
    const file = "input/big/Roget.mtx";

    _ = try read(file);
}
