const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const timer = std.time.Timer;

pub fn main() !void {
    const msg = "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains .";

    var start = try timer.start();
    var i: u32 = 0;
    // _ = i;

    // for (msg, 0..) |char, i| {
    //     print("({}) -> {c}\n", .{ i, char });
    // }
    // print("len:{}\n", .{msg.len});
    // const total = 3_000_000;
    const total = 2_000;
    while (i < total) : (i += 1_000) {
        var it = std.mem.tokenize(u8, msg, " ");
        while (it.next()) |item| {
            std.debug.print("{s}\n", .{item});
        }
        // print("i = {}\n", .{i});
    }
    print("n = {}\n", .{total / 1_000});

    // const x = true;
    // var a: u8 = 1;
    // try expect(x);
    // a += if (x) 1 else 0;
    // assert(a == 2);
    // print("{}\n", .{a});

    // Nanosegundos para milissegundos
    const end = start.read() / 1_000_000;
    print("{}\n", .{end});
    print("\n{}\n", .{std.fmt.fmtDuration(start.read())});
}

fn addFive(x: u8) u16 {
    var y: u16 = x + 5;
    {
        defer y -= 4;
    }
    return y;
}

test "func" {
    const y: u16 = addFive(1);
    print("\n{}\n", .{y});
    try expect(y == 2);
    assert(@TypeOf(y) == u16);
}
