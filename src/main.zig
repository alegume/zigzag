const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

const hb_files = @import("hb_files.zig");

pub fn main() !void {
    var start = try timer.start();

    const file = "input/tests/test1.mtx";

    const elements = try hb_files.read(file);
    for (elements) |e| print("{any}\n", .{e});
    // Nanosegundos para milissegundos
    // const end = start.read() / 1_000_000;
    // print("{}\n", .{end});
    print("\nTime: {}\n", .{std.fmt.fmtDuration(start.read())});
}
