const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

const hb_files = @import("hb_files.zig");

const SIZE = 900_000;

pub fn main() !void {
    // var start = try timer.start();

    // const file = "input/tests/test1.mtx";

    // const elements = try hb_files.read(file);
    // for (elements) |e| print("{any}\n", .{e});
    // // Nanosegundos para milissegundos
    // // const end = time / 1_000_000;
    // // print("{}\n", .{end});
    // print("\nTime: {}\n", .{std.fmt.fmtDuration(time)});

    var gpa: u8 = 0;
    var page: u8 = 0;
    var c: u8 = 0;
    const win = 1;
    const second = 0;
    var total_c: f64 = undefined;
    var total_g: f64 = undefined;
    var total_p: f64 = undefined;

    for (0..100) |_| {
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

fn page_allocator() !u64 {
    var start = try timer.start();

    const allocator = std.heap.page_allocator;
    // const size = std.math.pow(usize, 2, 20);
    const memory = try allocator.alloc(hb_files.Element, SIZE);
    defer allocator.free(memory);

    try expect(memory.len == SIZE);
    try expect(@TypeOf(memory) == []hb_files.Element);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    print("\n\t ** Page allocator **\n", .{});
    for (memory, 0..) |_, i|
        memory[i] = hb_files.Element{
            .v = @as(f64, @floatFromInt(i)),
            .i = i,
            .j = i,
        };
    for (memory, 0..) |_, i| {
        memory[i].v = (memory[i].v orelse 321) * @as(f64, @floatFromInt(i));
        memory[i].j *= 6;
        memory[i].j *= 7;
    }
    memory[0] = hb_files.Element{ .v = null, .i = 435, .j = 798 };
    memory[9999] = hb_files.Element{ .v = null, .i = 32435, .j = 87 };
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});
    // print("size: {}\n", .{size});
    // print("Mem used: {any} Mbytes\n", .{@sizeOf(usize) * size / (1024 * 1024)});

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

    const memory = try allocator.alloc(usize, SIZE);
    defer allocator.free(memory);

    try expect(memory.len == SIZE);
    try expect(@TypeOf(memory) == []usize);

    print("\n\t ** GPA allocator **\n", .{});
    for (memory, 0..) |_, i|
        memory[i] = i;
    for (memory, 0..) |_, i|
        memory[i] *= 3;
    memory[0] = 999;
    memory[9999] = 21;
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}

fn c_alloc() !u64 {
    var start = try timer.start();

    const allocator = std.heap.c_allocator;
    // const size = std.math.pow(usize, 2, 20);
    const memory = try allocator.alloc(usize, SIZE);
    defer allocator.free(memory);

    try expect(memory.len == SIZE);
    try expect(@TypeOf(memory) == []usize);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    print("\n\t ** C allocator **\n", .{});
    for (memory, 0..) |_, i|
        memory[i] = i;
    for (memory, 0..) |_, i|
        memory[i] *= 3;
    memory[0] = 999;
    memory[9999] = 21;
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}
