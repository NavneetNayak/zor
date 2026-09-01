const std = @import("std");
const server = @import("server.zig");

test "build sanity test" {
    try std.testing.expectEqual(1, 1);
}

test {
    std.testing.refAllDecls(server);
}
