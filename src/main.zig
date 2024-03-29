const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const CSR_Matrix = @import("csr_matrix.zig").CSR_Matrix;
const matrixToCSR = @import("csr_matrix.zig").matrixToCSR;
const csrFromFile = @import("csr_matrix.zig").csrFromFile;
const EntriesType = @import("matrix.zig").EntriesType;
const mm = @import("mm_files.zig");

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
                // const matrix = try mm.readAsMatrix(file, f64, allocator);
                // const csr_matrix = matrixToCSR(f64, matrix, allocator);
                const csr_matrix = try csrFromFile(f64, file, allocator);
                std.debug.print("nz_len: {any}; max_degree: {}\n", .{ csr_matrix.nz_len, csr_matrix.max_degree });
            },
            else => {
                // const matrix = try mm.readAsMatrix(file, usize, allocator);
                // const csr_matrix = matrixToCSR(usize, matrix, allocator);
                const csr_matrix = try csrFromFile(usize, file, allocator);
                std.debug.print("nz_len: {any}; max_degree: {}\n", .{ csr_matrix.nz_len, csr_matrix.max_degree });
            },
        }
    }
}

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
