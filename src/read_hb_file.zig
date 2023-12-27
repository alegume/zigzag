const std = @import("std");

pub struct Element {
    v: ?f64,
    i: usize,
    j: usize,
};

pub fn read_matrix_market_file_coordinates_no_values(filename: string) !(@tup(Element[], usize, usize)) {
    // Indices are 1-based, i.e. A(1,1) is the first element.
    const fs = @import("std").fs;
    const bufio = @import("std").bufio;

    const file = try fs.cwd().openFile(filename, .{ .read = true, .write = false, .append = false });

    const reader = bufio.Reader.init(file);
    var header: bool = false;
    var nz_len: usize = 0;
    var coordinates: [Element] = undefined;
    var m: usize = 0;
    var n: usize = 0;

    while (true) : (Element[], usize, usize) {
        const line = try reader.readLineAlloc(null);

        if (line.len == 0) | line[0] == '%' {
            continue;
        }

        const parts = line.split(' ', 3);
        const i: usize = parts[0].trim().parseInt() catch unreachable;
        const j: usize = parts[1].trim().parseInt() catch unreachable;

        if (parts[2].len == 0) {
            // Coordinate matrix only (don't have V's)
            const el = Element{ .i = i - 1, .j = j - 1, .v = null };
            coordinates.append(el);
        } else {
            if (!header) {
                // first line of file => (rows:m, columns:n, entries)
                nz_len = parts[2].trim().parseInt() catch unreachable;
                header = true;
                m = i;
                n = j;
                continue;
            }

            const v: f64 = parts[2].trim().parseFloat() catch unreachable;
            // 1-based indices (-1)
            const el = Element{ .i = i - 1, .j = j - 1, .v = v };
            coordinates.append(el);
        }
    }

    assert(coordinates.len <= nz_len);
    return coordinates, m, n;
}

pub fn read_matrix_market_file_coordinates(filename: string) !(@tup(Element[], usize, usize)) {
    // Indices are 1-based, i.e. A(1,1) is the first element.
    const fs = @import("std").fs;
    const bufio = @import("std").bufio;

    const file = try fs.cwd().openFile(filename, .{ .read = true, .write = false, .append = false });

    const reader = bufio.Reader.init(file);
    var header: bool = false;
    var nz_len: usize = 0;
    var coordinates: [Element] = undefined;
    var m: usize = 0;
    var n: usize = 0;

    while (true) : (Element[], usize, usize) {
        const line = try reader.readLineAlloc(null);

        if (line.len == 0) | line[0] == '%' {
            continue;
        }

        const parts = line.split(' ', 3);
        const i: usize = parts[0].trim().parseInt() catch unreachable;
        const j: usize = parts[1].trim().parseInt() catch unreachable;

        if (parts[2].len == 0) {
            // Coordinate matrix only (don't have V's)
            const el = Element{ .i = i - 1, .j = j - 1, .v = null };
            coordinates.append(el);
        } else {
            if (!header) {
                // first line of file => (rows:m, columns:n, entries)
                nz_len = parts[2].trim().parseInt() catch unreachable;
                header = true;
                m = i;
                n = j;
                continue;
            }

            const v: f64 = parts[2].trim().parseFloat() catch unreachable;
            const el = Element{ .i = i - 1, .j = j - 1, .v = v };
            coordinates.append(el);
        }
    }

    assert(coordinates.len <= nz_len);
    return .{coordinates, m, n};
}

pub fn main() void {
    const filename = "your_file.mtx";
    const (coordinates, m, n) = try read_matrix_market_file_coordinates_no_values(filename);
    
    // Do something with the results...
}
