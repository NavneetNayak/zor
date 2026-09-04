const std = @import("std");

const zor = @import("zor");

const api = @import("api.zig");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var client = zor.initClient(api);
    try client.connect(io, "0.0.0.0", 8000);

    const Vecf32 = api.MathService.Vecf32;
    const vec = try client.call(io, arena, api.MathService.multiplyf32Vecf32, .{ 2.0, Vecf32{ .x = 1.0, .y = 3.5 } });
    std.debug.print("vec: {}\n", .{vec});

    const resp = try client.call(io, arena, api.MathService.dividei32, .{ 2, 0 });
    const ans = try resp;
    std.debug.print("ans: {}", .{ans});

    try client.call(io, arena, api.TestService.stringTest, .{"Hello"});
}
