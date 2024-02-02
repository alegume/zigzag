const std = @import("std");

fn Impls(comptime Object: type) type {
    return struct {
        pub const Raw = struct {
            allocator: std.mem.Allocator,

            pub fn init(allocator: std.mem.Allocator) @This() {
                return .{ .allocator = allocator };
            }

            pub fn new(self: @This()) !*Object {
                return try self.allocator.create(Object);
            }

            pub fn delete(self: @This(), obj: *Object) void {
                self.allocator.destroy(obj);
            }

            pub fn deinit(self: *@This()) void {
                _ = self;
            }
        };

        const Arena = struct {
            arena: std.heap.ArenaAllocator,

            pub fn init(allocator: std.mem.Allocator) @This() {
                return .{ .arena = std.heap.ArenaAllocator.init(allocator) };
            }

            pub fn deinit(self: *@This()) void {
                self.arena.deinit();
            }

            pub fn new(self: *@This()) !*Object {
                return try self.arena.allocator().create(Object);
            }

            pub fn delete(self: *@This(), obj: *Object) void {
                self.arena.allocator().destroy(obj);
            }
        };

        const Pool = struct {
            const List = std.TailQueue(Object);

            arena: std.heap.ArenaAllocator,
            free: List = .{},

            pub fn init(allocator: std.mem.Allocator) @This() {
                return .{ .arena = std.heap.ArenaAllocator.init(allocator) };
            }

            pub fn deinit(self: *@This()) void {
                self.arena.deinit();
            }

            pub fn new(self: *@This()) !*Object {
                const obj = if (self.free.popFirst()) |item|
                    item
                else
                    try self.arena.allocator().create(List.Node);
                return &obj.data;
            }

            pub fn delete(self: *@This(), obj: *Object) void {
                const node = objectToNode(obj);
                self.free.append(node);
            }

            fn objectToNode(obj: *Object) *List.Node {
                return @fieldParentPtr(List.Node, "data", obj);
            }
        };
    };
}

const small_rounds = 2_500_0;
const medium_rounds = 1_000_0;
const big_rounds = 25_0;

test "gpa(small)" {
    var impl = Impls(SmallObject).Raw.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("gpa/small", SmallObject, &impl, small_rounds);
}

test "turbopool(small)" {
    var impl = Impls(SmallObject).Pool.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("pool/small", SmallObject, &impl, small_rounds);
}

test "arena(small)" {
    var impl = Impls(SmallObject).Arena.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("arena/small", SmallObject, &impl, small_rounds);
}

test "gpa(big)" {
    var impl = Impls(BigObject).Raw.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("gpa/big", BigObject, &impl, big_rounds);
}

test "turbopool(big)" {
    var impl = Impls(BigObject).Pool.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("pool/big", BigObject, &impl, big_rounds);
}

test "arena(big)" {
    var impl = Impls(BigObject).Arena.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("arena/big", BigObject, &impl, big_rounds);
}

test "gpa(medium)" {
    var impl = Impls(MediumObject).Raw.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("gpa/medium", MediumObject, &impl, medium_rounds);
}

test "turbopool(medium)" {
    var impl = Impls(MediumObject).Pool.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("pool/medium", MediumObject, &impl, medium_rounds);
}

test "arena(medium)" {
    var impl = Impls(MediumObject).Arena.init(std.testing.allocator);
    defer impl.deinit();

    try runPerfTest("arena/medium", MediumObject, &impl, medium_rounds);
}

fn runPerfTest(tag: []const u8, comptime Object: type, pool: anytype, max_rounds: usize) !void {
    const begin_time = std.time.nanoTimestamp();

    var slots = std.BoundedArray(*Object, 256){};
    var rounds: usize = max_rounds;

    var random_source = std.rand.DefaultPrng.init(1337);
    const rng = random_source.random();

    var max_fill_level: usize = 0;
    var allocs: usize = 0;
    var frees: usize = 0;

    while (rounds > 0) {
        rounds -= 1;

        const free_chance = @as(f32, @floatFromInt(slots.len)) / @as(f32, @floatFromInt(slots.buffer.len - 1)); // more elements => more frees
        const alloc_chance = 1.0 - free_chance; // more elements => less allocs

        if (slots.len > 0) {
            if (rng.float(f32) <= free_chance) {
                const index = rng.intRangeLessThan(usize, 0, slots.len);
                const ptr = slots.swapRemove(index);
                pool.delete(ptr);

                frees += 1;
            }
        }

        if (slots.len < slots.capacity()) {
            if (rng.float(f32) <= alloc_chance) {
                const item = try pool.new();
                slots.appendAssumeCapacity(item);

                allocs += 1;
            }
        }

        max_fill_level = @max(max_fill_level, slots.len);
    }

    for (slots.slice()) |ptr| {
        pool.delete(ptr);
    }

    const end_time = std.time.nanoTimestamp();

    try std.io.getStdOut().writer().print("time={d: >10.2}us, max fill level={d: >3}%, allocs={d:6}, frees={d:6}, test={s}\n", .{
        @as(f32, @floatFromInt(end_time - begin_time)) / 1000.0,
        100 * max_fill_level / slots.buffer.len,
        allocs,
        frees,
        tag,
    });
}

const SmallObject = struct {
    small: [1]u8,
};

const MediumObject = struct {
    // medium: [8192]u8,
    medium: [1024]u8,
};

const BigObject = struct {
    // big: [1024 * 1024]u8,
    big: [20240]u8,
};
