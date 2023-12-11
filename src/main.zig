const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const timer = @import("std").time.Timer;

pub fn main() !void {
    const msg = "On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains.";

    var start = try timer.start();
    var i: u32 = 0;

    while (i < 3_000_000) : (i += 1) {
        const it = std.mem.tokenize(u8, msg, " ");
        _ = it;
        // while (it.next()) |item| {
        //     std.debug.print("{s}\n", .{item});
        // }
    }

    // Nanosegundos para milissegundos
    const end = start.read() / 1_000_000;
    print("{}\n", .{end});
    print("{}\n", .{std.fmt.fmtDuration(start.read())});
}
