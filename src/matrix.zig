const std = @import("std");
const mm = @import("mm_files.zig");
const EntriesType = mm.EntriesType;
const assert = std.debug.assert;
const expect = std.testing.expect;

pub fn Matrix(comptime T: type) type {
    return struct {
        data: [][]?T = undefined,
        row: usize,
        column: usize,
        entries_type: EntriesType = undefined,
        symmetric: bool = false,
        nz_len: usize = 0,

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

        pub fn print(self: Self) void {
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

pub fn readAsMatrix(comptime T: type, path: []const u8, allocator: std.mem.Allocator) !Matrix(T) {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var lines_read: usize = 0;
    var n_lines: usize = 0;
    var m: usize = 0;
    var n: usize = 0;
    var matrix = try allocator.create(Matrix(T));

    const is_symmetric = mm.symmetry(path);

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

            matrix.* = Matrix(T).init(m, n, allocator);
            matrix.nz_len = n_lines;
        } else {
            // Format => I1  J1  M(I1, J1)
            var it = std.mem.splitScalar(u8, line, ' ');
            const i = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;

            const j = std.fmt.parseInt(usize, it.next() orelse unreachable, 10) catch unreachable;

            const val = it.next() orelse null;
            // Patern Matrix (null and 1)
            if (val == null) {
                matrix.data[i-1][j-1] = 1;
                if (try is_symmetric)
                    matrix.data[j-1][i-1] = 1;
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
    matrix.entries_type = try mm.entriesType(path);

    return matrix.*;
}

test "testing reading real assymetric matrix" {
    const file = "input/tests/b1_ss.mtx";
    const et = try mm.entriesType(file);
    try expect(et == EntriesType.float);
    const s = try mm.symmetry(file);
    try expect(s == false);

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const matrix = try readAsMatrix(f64, file, allocator);
    const m1 = [7][7]?f64 {
        [_]?f64 {null, 1, 1, 1, null, null, null},
        [_]?f64 {null, -1, null, null, 0.45, null, null},
        [_]?f64 {null, null, -1, null, null, 0.1, null},
        [_]?f64 {null, null, null, -1, null, null, 0.45},
        [_]?f64 {-0.03599942, null, null, null, 1, null, null},
        [_]?f64 {-0.0176371, null, null, null, null, 1, null},
        [_]?f64 {-0.007721779, null, null, null, null, null, 1},
    };

    for (m1, 0..) |row, i| {
        for (row, 0..) |val, j| {
            try expect(matrix.data[i][j] == val);
        }
    }
}

test "reading HB file as matrix" {
    const file1 = "input/tests/test1.mtx";
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const matrix1 = try readAsMatrix(u8, file1, allocator);
    var m1:[][]?u8 = undefined;
    m1 = allocator.alloc([]?u8, 4) catch unreachable;
    for (0..4) |i| {
        m1[i] = allocator.alloc(?u8, 4) catch unreachable;
    }
    @memcpy(m1[0], ([_]?u8 {5, null, null, null})[0..]);
    @memcpy(m1[1], ([_]?u8 {null, 8, null, null})[0..]);
    @memcpy(m1[2], ([_]?u8 {null, null, 3, null})[0..]);
    @memcpy(m1[3], ([_]?u8 {null, 6, null, null})[0..]);
    try expect( @TypeOf(matrix1.data) == @TypeOf(m1));
    for (m1, 0..) |row, i|
        for (row, 0..) |el, j|
            try expect(el == matrix1.data[i][j]);
}