const std = @import("std");
const net = std.Io.net;

const cprint = std.fmt.comptimePrint;

const common = @import("common.zig");
const transport = @import("transport.zig");

pub const ZorServerError = error{};

pub fn Route(
    comptime RouteSpec: type,
    comptime rpc_fn: anytype,
) type {
    return struct {
        pub const _RouteSpec = RouteSpec;
        pub const _rpc_fn = rpc_fn;
    };
}

pub fn Server(comptime ApiSpec: type, comptime ApiImpl: type) type {
    const RouteSpecs = common.parseRouteSpecs(ApiSpec);
    const routes = parseRoutes(RouteSpecs, ApiImpl);

    return struct {
        const Self = @This();

        fn handleRpc(
            arena: std.mem.Allocator,
            req_message_body: transport.MessageBody,
            rpc_id_u16: u16,
        ) !transport.MessageBody {
            // generate static routing
            switch (rpc_id_u16) {
                inline 0...(routes.len - 1) => |route_id| {
                    const route = routes[route_id];
                    const RouteSpec = route._RouteSpec;

                    const params = req_message_body.deserializeMessageBody(RouteSpec.Params);
                    const ret = @call(.auto, route._rpc_fn, params);

                    return try transport.MessageBody.serializeMessageBody(arena, ret, RouteSpec.Ret);
                },
                else => return common.ZorRpcError.InvalidMethod,
            }
        }

        fn handleConn(arena: std.mem.Allocator, io: std.Io, conn: std.Io.net.Stream) void {
            defer conn.close(io);

            var recv_buffer: [transport.recvBufferSize]u8 = undefined;
            var send_buffer: [transport.recvBufferSize]u8 = undefined;

            var reader = conn.reader(io, &recv_buffer);
            var writer = conn.writer(io, &send_buffer);

            while (true) {
                const req_message_header, const req_message_body = transport.readMessage(
                    arena,
                    &reader.interface,
                ) catch break;

                const ret_message = handleRpc(
                    arena,
                    req_message_body,
                    req_message_header.rpc_id_u16,
                ) catch break;

                transport.writeMessage(
                    &writer.interface,
                    .Response,
                    req_message_header.rpc_id_u16,
                    ret_message,
                ) catch break;
                writer.interface.flush() catch break;
            }
        }

        pub fn serve(_: *const Self, arena: std.mem.Allocator, io: std.Io, host: []const u8, port: u16) !void {
            const addr = try net.IpAddress.parseIp4(host, port);

            var listening = try addr.listen(io, .{
                .mode = net.Socket.Mode.stream,
                .protocol = net.Protocol.tcp,
            });
            defer listening.deinit(io);

            var group: std.Io.Group = .init;
            defer group.cancel(io);

            while (true) {
                const conn = listening.accept(io) catch continue;
                try group.concurrent(io, handleConn, .{ arena, io, conn });
            }
        }
    };
}

pub fn parseRoutes(comptime RouteSpecs: []const type, comptime Impl: type) []const type {
    comptime var routes: [RouteSpecs.len]type = undefined;

    for (RouteSpecs) |RouteSpec| {
        const service_name = RouteSpec._service_name;
        const rpc_name = RouteSpec._rpc_name;

        const ServiceImpl =
            if (@hasDecl(Impl, service_name))
                @field(Impl, service_name)
            else
                @compileError(cprint("No implementation provided for service: {s}", .{service_name}));

        const RpcImpl =
            if (@hasDecl(ServiceImpl, rpc_name))
                @field(ServiceImpl, rpc_name)
            else
                @compileError(cprint("No rpc implementation for {s} provided.", .{rpc_name}));

        if (RouteSpec._RpcFn != @TypeOf(RpcImpl))
            @compileError(cprint("Rpc signature for {s} doesn't match impl", .{rpc_name}));

        routes[@intFromEnum(RouteSpec.id)] = Route(RouteSpec, RpcImpl);
    }

    const routes_final: [routes.len]type = routes[0..routes.len].*;
    return &routes_final;
}
