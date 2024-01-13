const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

pub fn main() !void {
    var start = try timer.start();

    // Nanosegundos para milissegundos
    // const end = start.read() / 1_000_000;
    // print("{}\n", .{end});
    print("\n{}\n", .{std.fmt.fmtDuration(start.read())});
}
