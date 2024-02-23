// https://math.nist.gov/MatrixMarket/formats.html
const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const CSR_Matrix = @import("csr_matrix.zig").CSR_Matrix;


pub const EntriesType = enum{int, float, complex, pattern};
pub const ReadingError = error{HeaderError};

pub fn entriesType(path: []const u8) !EntriesType {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    // header line (first line)
    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var hl = std.mem.splitBackwardsScalar(u8, first_line.?, ' ');

    // Ignore symmetry
    _ = hl.next().?;

    // Read type
    const data_type:[]const u8 = hl.next().?;
    if (std.mem.eql(u8, data_type , "real")) {
        return EntriesType.float;
    } else if (std.mem.eql(u8, data_type, "pattern")) {
        return EntriesType.pattern;
    } else if (std.mem.eql(u8, data_type, "integer")) {
        return EntriesType.int;
    } else if (std.mem.eql(u8, data_type, "complex")) {
        std.debug.print("Complex type detected! Considering as pattern matrix.", .{});
        return EntriesType.pattern;
    } else {
        std.debug.print("No type detected! Considering as pattern matrix.", .{});
        return EntriesType.pattern;
    }
}

pub fn symmetry(path: []const u8) !bool {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    // header line (first line)
    const first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var hl = std.mem.splitBackwardsScalar(u8, first_line.?, ' ');

    // Return symmetry (bool)
    return std.mem.eql(u8, hl.next().?, "symmetric");
}



