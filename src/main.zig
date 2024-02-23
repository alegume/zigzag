const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const CSR_Matrix = @import("csr_matrix.zig").CSR_Matrix;
const matrixToCSR = @import("csr_matrix.zig").matrixToCSR;
const MatrixEntries = @import("matrix.zig").MatrixEntries;
const mm = @import("mm_files.zig");


const print = std.debug.print;
// const expect = std.testing.expect;
// const test_allocators = @import("test_allocators.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // First arg is the executable itself
    for (std.os.argv[1..]) |arg| {
        const file = std.mem.span(arg);
        // std.debug.print("  {s}\n", .{arg});
        const entries_type = try mm.entriesType(file);
        switch (entries_type) {
            .float => {
                const matrix = try mm.readAsMatrix(file, f64, allocator);
                const csr_matrix = matrixToCSR(f64, matrix, allocator);
                std.debug.print("nz_len: {any}\n", .{csr_matrix.nz_len});
            },
            else => {
                const matrix = try mm.readAsMatrix(file, usize, allocator);
                const csr_matrix = matrixToCSR(usize, matrix, allocator);
                std.debug.print("nz_len: {any}\n", .{csr_matrix.nz_len});
            },
        }
    }
}



// fn increment(x: *u8) void {
//     x.* += 1;
// }

// test "pointers" {
//     var p: u8 = 1;
//     increment(&p);
//     try expect(p == 2);
// }

// test "usize" {
//     try expect(@sizeOf(usize) == @sizeOf(*u8));
//     try expect(@sizeOf(isize) == @sizeOf(*u8));
// }

// fn total(vec: []const usize) usize {
//     var acc: usize = 0;
//     for (vec) |value| {
//         acc += value;
//     }
//     return acc;
// }

// test "total slice" {
//     const vec = [_]usize{ 100, 1000, 1000, 10, 1 };
//     try expect(total(vec[0..3]) == 2100);
//     try expect(total(vec[0..5]) == 2111);
//     try expect(total(vec[0..]) == 2111);
// }

// test "nested continue" {
//     var count: usize = 0;
//     for ([_]i32{ 1, 2, 3, 4, 5, 6, 7 }) |_| {
//         for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
//             count += 1;
//             break;
//         }
//     }
//     try expect(count == 7);
// }

// fn hangeHasVal(begin: usize, end: usize, val: usize) bool {
//     var i: usize = begin;
//     return while (i <= end) : (i += 1) {
//         if (i == val)
//             break true;
//     } else false;
// }

// test "hangeHasVal" {
//     try expect(hangeHasVal(0, 10, 60) == false);
// }

// test "contains 6" {
//     var index: ?usize = null;
//     const vec = [_]f64{ 1, 2, 3, 4, 5.6, 6.9 };
//     for (vec, 0..) |v, i| {
//         if (v == 6) index = i;
//     }
//     try expect(index == undefined);
// }

// const Error = error{WrongPerson};
// fn helloAleOrError(name: []const u8) !?bool {
//     if (std.mem.eql(u8, name, "Ale")) {
//         print("Hello, {s}\n", .{name});
//         return true;
//     } else if (std.mem.eql(u8, name, "ale")) {
//         return false;
//     }
//     if (std.mem.eql(u8, name, "xandi")) {
//         print("No harmonia do samba allowed, {s}\n", .{name});
//         return null;
//     }
//     return Error.WrongPerson;
// }

// test "first error tpe" {
//     const name = "xandi";

//     // Se retornou true ou false
//     if (helloAleOrError(name)) |not_xandi| {
//         if (not_xandi) |ale| {
//             if (ale) {
//                 print("Ale (Maiuscula)\n", .{});
//             } else {
//                 print("ale (minuscula)\n", .{});
//             }
//         } else {
//             print("Don't play axé on me. Sorry not sorry", .{});
//         }
//         // Se retornou Error
//     } else |err| {
//         std.debug.print("Error: {}\n", .{err});
//     }
// }

// test "matrix" {
//     var matrix:[2][2]usize = undefined;
    
//     matrix = [_] [2]usize{
//         [_]usize {1, 2},
//         [_]usize {1, 2},
//     };
//     print("\n{any}\n", .{matrix});
// }

// test "null" {
//     var x:?u8 = undefined;
//     x = null;

//     if (x) |_| {
//         x = 11;
//     } else {
//         x = 0;
//     }

//     try expect(x == 0);
// }