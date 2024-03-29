const std = @import("std");
const print = std.debug.print;
const timer = std.time.Timer;
const expect = std.testing.expect;

const hb = @import("hb_files.zig");

// const SIZE = 6_000;
const SIZE = 1_000_000;
const REPETITIONS = 100;

pub fn test_allocators() !void {
    var gpa: u8 = 0;
    var page: u8 = 0;
    var c: u8 = 0;
    const win = 1;
    const second = 0;
    var total_c: f64 = undefined;
    var total_g: f64 = undefined;
    var total_p: f64 = undefined;

    for (0..REPETITIONS) |_| {
        const p = try page_allocator();
        const g = try gpa_alloc();
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
    // try testElement(allocator);
    try testCSR_Matrix(allocator);
}

fn testCSR_Matrix(allocator: std.mem.Allocator) !void {
    var matrix: hb.CSR_Matrix = undefined;
    matrix.i = try allocator.alloc(usize, SIZE);
    matrix.j = try allocator.alloc(usize, SIZE);
    matrix.v = try allocator.alloc(?f64, SIZE);
    defer {
        allocator.free(matrix.i);
        allocator.free(matrix.j);
        allocator.free(matrix.v);
    }
    // for (matrix.i, 0..) |_, index| matrix.i[index] = index;
    // print("{any}\n", .{matrix});

    try expect(matrix.j.len == SIZE);
    try expect(@TypeOf(matrix.i) == []usize);

    for (matrix.i, 0..) |_, i| {
        matrix.v[i] = @as(f64, @floatFromInt(i));
        matrix.i[i] = i;
        matrix.j[i] = i;
    }
    for (matrix.i, 0..) |_, i| {
        matrix.v[i] = (matrix.v[i] orelse 321) * @as(f64, @floatFromInt(i));
        matrix.i[i] *= 6;
        matrix.j[i] *= 7;
    }
    matrix.v[0] = null;
    matrix.i[0] = 435;
    matrix.j[0] = 798;
    matrix.v[matrix.i.len - 1] = null;
    matrix.i[matrix.i.len - 1] = 32435;
    matrix.j[matrix.i.len - 1] = 87;
}

fn testElement(allocator: std.mem.Allocator) !void {
    const matrix: []hb.Element = try allocator.alloc(hb.Element, SIZE);
    defer allocator.free(matrix);

    try expect(matrix.len == SIZE);
    try expect(@TypeOf(matrix) == []hb.Element);
    try expect(@sizeOf(usize) == @sizeOf(u64));

    for (matrix, 0..) |_, i|
        matrix[i] = hb.Element{
            .v = @as(f64, @floatFromInt(i)),
            .i = i,
            .j = i,
        };
    for (matrix, 0..) |_, i| {
        matrix[i].v = (matrix[i].v orelse 321) * @as(f64, @floatFromInt(i));
        matrix[i].i *= 6;
        matrix[i].j *= 7;
    }
    matrix[0] = hb.Element{ .v = null, .i = 435, .j = 798 };
    matrix[matrix.len - 1] = hb.Element{ .v = null, .i = 32435, .j = 87 };
}

fn page_allocator() !u64 {
    var start = try timer.start();
    const allocator = std.heap.page_allocator;

    // print("\n\t ** Page allocator **\n", .{});
    try tester(allocator);
    const time = start.read();
    // print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

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

    // print("\n\t ** GPA allocator **\n", .{});
    try tester(allocator);
    const time = start.read();
    // print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}

fn c_alloc() !u64 {
    var start = try timer.start();
    const allocator = std.heap.page_allocator;

    // print("\n\t ** C allocator **\n", .{});
    try tester(allocator);
    const time = start.read();
    // print("Bench Time: {}\n", .{std.fmt.fmtDuration(time)});

    return time;
}

test "buffer" {
    const S = 30_000_000;
    var buffer: [S]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, S);
    defer allocator.free(memory);

    try expect(memory.len == S);
    try expect(@TypeOf(memory) == []u8);

    for (buffer, 0..) |_, i| memory[i] = @intCast(@mod(i, 255));
    print("\n {any} \n", .{memory[191]});
    print("\nsize:{}\n", .{8 * S});
}
