const std = @import("std");

const common = @import("common.zig");
const server = @import("server.zig");
const client = @import("client.zig");

pub fn initServer(ApiSpec: type, comptime api_impl: anytype) server.Server {
    const routes: []const type = common.parseRoutesFromSpec(ApiSpec, api_impl);
    return server.Server{ .routes = routes };
}

pub fn initClient(ApiSpec: type) client.Client {
    _ = ApiSpec;
    unreachable;
}

test "server test" {
    const ApiSpec = struct {
        pub const ParityService = struct {
            pub fn isEven(_: i32) void {
                unreachable;
            }
            pub fn isOdd(_: i64) void {
                unreachable;
            }
        };
    };

    const ParityServiceImpl = struct {
        const _std = @import("std");

        pub fn isEven(operand: i32) void {
            _std.debug.print("Yay! it works!, also {}\n", .{operand});
        }

        pub fn isOdd(operand: i64) void {
            _std.debug.print("Yay! This also works, also {}\n", .{operand});
        }
    };

    const _server = comptime initServer(ApiSpec, .{
        .ParityService = ParityServiceImpl,
    });

    const even_bytes = std.mem.toBytes(@as(i32, 2));
    _ = try _server.handleRPC(0, .{ .bytes = &even_bytes });

    const odd_bytes = std.mem.toBytes(@as(i64, 3));
    _ = try _server.handleRPC(1, .{ .bytes = &odd_bytes });
}
