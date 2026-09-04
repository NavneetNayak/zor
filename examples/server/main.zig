const std = @import("std");

const zor = @import("zor");

const api = @import("api.zig");
const api_impl = @import("api_impl.zig");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    const server = comptime zor.initServer(api, api_impl);
    try server.serve(arena, io, "0.0.0.0", 8000);
}
