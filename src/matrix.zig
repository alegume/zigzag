const std = @import("std");

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