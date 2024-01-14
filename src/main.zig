const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

const hb_files = @import("hb_files.zig");

const size = 5_000_000_000;

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

    for (0..10) |_| {
        const g = try gpa_alloc();
        const c_time = try c_alloc();
        const p = try page_allocator();
        if (p < g) {
            if (c_time < p) {
                c += 2;
                page += 1;
            } else {
                page += 2;
                c += 1;
            }
        } else {
            if (c_time < g) {
                c += 2;
                gpa += 1;
            } else {
                gpa += 2;
                c += 1;
            }
        }
        print("\n gpa:{} ; page:{} ; c:{} \n", .{ gpa, page, c });
    }
}

test "basics" {
    const elements = [_]i32{ 1, 2, 3, -9, -100 };
    for (elements, 0..) |e, i| {
        // print("{any}\n", .{e});
        try expect(e == elements[i]);
    }

    // // Many pointers
    // const mp: [*]usize = [_]usize{};
    // print("{}\n", .{mp});

}

fn page_allocator() !u64 {
    var start = try timer.start();

    const allocator = std.heap.page_allocator;
    // const size = std.math.pow(usize, 2, 20);
    const memory = try allocator.alloc(usize, size);
    defer allocator.free(memory);

    try expect(memory.len == size);
    try expect(@TypeOf(memory) == []usize);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    print("\n\t ** Page allocator **\n", .{});
    // for (memory, 0..) |_, i|
    //     memory[i] = i;
    // for (memory, 0..) |_, i|
    //     memory[i] *= 3;
    memory[0] = 999;
    memory[9999] = 21;
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

    const memory = try allocator.alloc(usize, size);
    defer allocator.free(memory);

    try expect(memory.len == size);
    try expect(@TypeOf(memory) == []usize);

    print("\n\t ** GPA allocator **\n", .{});
    // for (memory, 0..) |_, i|
    //     memory[i] = i;
    // for (memory, 0..) |_, i|
    //     memory[i] *= 3;
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
    const memory = try allocator.alloc(usize, size);
    defer allocator.free(memory);

    try expect(memory.len == size);
    try expect(@TypeOf(memory) == []usize);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    print("\n\t ** C allocator **\n", .{});
    // for (memory, 0..) |_, i|
    //     memory[i] = i;
    // for (memory, 0..) |_, i|
    //     memory[i] *= 3;
    memory[0] = 999;
    memory[9999] = 21;
    const time = start.read();

    print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}
