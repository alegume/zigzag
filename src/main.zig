const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

const hb_files = @import("hb_files.zig");

const SIZE = 6_000;
const REPETITIONS = 100;

pub fn main() !void {
    // var start = try timer.start();

    // const file = "input/tests/test1.mtx";

    // const elements = try hb_files.read(file);
    // for (elements) |e| print("{any}\n", .{e});
    // // Nanosegundos para milissegundos
    // // const end = time / 1_000_000;
    // // print("{}\n", .{end});
    // print("\nTime: {}\n", .{std.fmt.fmtDuration(time)});

    try test_allocators();
}

fn test_allocators() !void {
    var gpa: u8 = 0;
    var page: u8 = 0;
    var c: u8 = 0;
    const win = 1;
    const second = 0;
    var total_c: f64 = undefined;
    var total_g: f64 = undefined;
    var total_p: f64 = undefined;

    for (0..REPETITIONS) |_| {
        const g = try gpa_alloc();
        const p = try page_allocator();
        const c_time = try c_alloc();
        if (p < g) {
            if (c_time < p) {
                c += win;
                page += second;
            } else {
                page += win;
                c += second;
            }
        } else {
            if (c_time < g) {
                c += win;
                gpa += second;
            } else {
                gpa += win;
                c += second;
            }
        }
        total_c += @as(f64, @floatFromInt(c_time));
        total_p += @as(f64, @floatFromInt(p));
        total_g += @as(f64, @floatFromInt(g));
        print("\n gpa:{} ; page:{} ; c:{} \n", .{ gpa, page, c });
        print("\n TOTAL time \n g:{} \n p:{} \n c:{} \n", .{ total_g, total_p, total_c });
        const percent: f64 = (total_c - total_p) / total_c * 100;
        print("c - page: \n {d} % \n", .{percent});
    }
}

fn tester(allocator: std.mem.Allocator) !void {
    try testElement(allocator);
}

fn testElement(allocator: std.mem.Allocator) !void {
    const matrix = try allocator.alloc(hb_files.Element, SIZE);
    defer allocator.free(matrix);

    try expect(matrix.len == SIZE);
    try expect(@TypeOf(matrix) == []hb_files.Element);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    print("\n\t ** Page allocator **\n", .{});
    for (matrix, 0..) |_, i|
        matrix[i] = hb_files.Element{
            .v = @as(f64, @floatFromInt(i)),
            .i = i,
            .j = i,
        };
    for (matrix, 0..) |_, i| {
        matrix[i].v = (matrix[i].v orelse 321) * @as(f64, @floatFromInt(i));
        matrix[i].j *= 6;
        matrix[i].j *= 7;
    }
    matrix[0] = hb_files.Element{ .v = null, .i = 435, .j = 798 };
    matrix[999] = hb_files.Element{ .v = null, .i = 32435, .j = 87 };
}

fn page_allocator() !u64 {
    var start = try timer.start();
    const allocator = std.heap.page_allocator;
    try tester(allocator);
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}

fn gpa_alloc() !u64 {
    var start = try timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    try tester(allocator);

    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}

fn c_alloc() !u64 {
    var start = try timer.start();

    const allocator = std.heap.c_allocator;
    try tester(allocator);
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}
