const std = @import("std");
const Matrix = @import("matrix.zig").Matrix;
const readAsMatrix = @import("mm_files.zig").readAsMatrix;
// const assert = std.debug.assert;
// const expect = std.testing.expect;

pub const CSR_Matrix = struct { v: []?f64, i: []usize, j: []usize };




test "testing" {
    // const file = "input/apache2.mtx";
    // const file = "input/general/bcspwr01.mtx";
    // const file = "input/big/nasa2910.mtx";
    // const file = "input/big/Roget.mtx";
    const file = "input/tests/b1_ss.mtx";
    // const file = "input/tests/test1.mtx";

    // var matrix = try readAsMatrix(file, f64);
    // matrix.print();

    _ = try readAsMatrix(file, f64);
}