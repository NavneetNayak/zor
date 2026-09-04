const std = @import("std");
const net = std.Io.net;

const cprint = std.fmt.comptimePrint;

const common = @import("common.zig");
const transport = @import("transport.zig");

pub const ZorClientError = error{
    NotConnectedToServer,
};

pub fn Client(comptime ApiSpec: type) type {
    const RouteSpecs = common.parseRouteSpecs(ApiSpec);

    // have to return custom type
    // otherwise client holds half comptime state and half runtime state
    return struct {
        const Self = @This();

        server_conn: ?net.Stream = null,

        pub fn connect(self: *Self, io: std.Io, server_host: []const u8, server_port: u16) !void {
            const server_addr = try net.IpAddress.parseIp4(server_host, server_port);
            self.server_conn = try server_addr.connect(io, .{ .mode = .stream });
        }

        pub fn call(
            self: *Self,
            io: std.Io,
            arena: std.mem.Allocator,
            comptime RpcFn: anytype,
            params: anytype,
            // nested error union, outer error is zor error
        ) !routeFor(@TypeOf(RpcFn)).Ret {
            if (self.server_conn == null) return ZorClientError.NotConnectedToServer;

            var write_buf: [transport.recvBufferSize]u8 = undefined;
            var read_buf: [transport.recvBufferSize]u8 = undefined;

            var writer = self.server_conn.?.writer(io, &write_buf);
            var reader = self.server_conn.?.reader(io, &read_buf);

            const RouteSpec = comptime routeFor(@TypeOf(RpcFn));
            const req_message_body = try transport.MessageBody.serializeMessageBody(
                arena,
                params,
                RouteSpec.Params,
            );

            try transport.writeMessage(&writer.interface, .Request, @intFromEnum(RouteSpec.id), req_message_body);
            try writer.interface.flush();

            _, const resp_message_body = try transport.readMessage(
                arena,
                &reader.interface,
            );
            return resp_message_body.deserializeMessageBody(RouteSpec.Ret);
        }

        fn routeFor(comptime Fn: type) type {
            return inline for (RouteSpecs) |route| {
                if (route._RpcFn == Fn) break route;
            } else @compileError(cprint("Rpc not found", .{}));
        }
    };
}
