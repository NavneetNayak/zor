const std = @import("std");
const cprint = std.fmt.comptimePrint;

const Route = struct {
    pub const Id = enum(u8) { _ };

    id: Id = @enumFromInt(0),
    RpcFnType: type,
    rpc_fn: *anyopaque,
};

// Support upto maxRoutes unique RPCs
const maxRoutes = 4096;

fn Server(Impl: type) type {
    return struct {
        const Self = @This();

        routes: []const Route,
        impl: Impl,

        pub fn init(comptime routes: []const Route, comptime impl: anytype) Self {
            return Self{
                .routes = routes,
                .impl = impl,
            };
        }

        pub fn handleRPC(comptime self: *const Self, message: anytype) void {
            const rpcId = message.rpcId;

            // Generate static routing
            inline for (self.routes) |route| {
                if (route.id == @as(Route.Id, @enumFromInt(rpcId))) {
                    const callable_rpc: *route.RpcFnType = @ptrCast(@alignCast(route.rpc_fn));

                    @call(.auto, callable_rpc.*, message.params);
                    return;
                }
            }
        }
    };
}

fn parseRouteFromSpec(comptime ServiceSpec: type, comptime service_impl: anytype, comptime rpc_decl: anytype, comptime id: u8) Route {
    const rpc_name = rpc_decl.name;
    const RpcSpec = @field(ServiceSpec, rpc_name);

    const rpc_impl =
        if (@hasDecl(service_impl, rpc_name))
            @field(service_impl, rpc_name)
        else
            @compileError(cprint("No rpc implementation for {s} provided.", .{rpc_name}));

    if (@TypeOf(RpcSpec) != @TypeOf(rpc_impl))
        @compileError(cprint("Rpc signature for {s} doesn't match impl", .{rpc_name}));

    const rpc_ptr: *anyopaque = @constCast(&rpc_impl);
    return Route{
        .id = @enumFromInt(id),
        .RpcFnType = @TypeOf(rpc_impl),
        .rpc_fn = rpc_ptr,
    };
}

fn parseServiceFromSpec(comptime ApiSpec: type, comptime impl: anytype, comptime service_decl: anytype) struct { type, type } {
    const service_name = service_decl.name;
    const ServiceSpec = @field(ApiSpec, service_name);

    const service_impl =
        if (@hasField(@TypeOf(impl), service_name))
            @field(impl, service_name)
        else
            @compileError(cprint("No implementation provided for service: {s}", .{service_name}));

    if (@TypeOf(ServiceSpec) != @TypeOf(service_impl))
        @compileError(cprint("Service signature for {s} doesn't match impl", .{service_name}));

    return .{ ServiceSpec, service_impl };
}

fn ParseServerFromSpec(comptime ApiSpec: type, comptime impl: anytype) Server(@TypeOf(impl)) {
    // TODO: allow unrestricted number of routes
    comptime var routes: [maxRoutes]Route = undefined;
    comptime var numRoutes = 0;

    const service_decls = @typeInfo(ApiSpec).@"struct".decls;

    // validate & parse routes from spec and impl
    for (service_decls) |service_decl| {
        const Service = parseServiceFromSpec(ApiSpec, impl, service_decl);
        const ServiceSpec = Service.@"0";
        const service_impl = Service.@"1";

        const rpc_decls = @typeInfo(ServiceSpec).@"struct".decls;

        for (rpc_decls, 0..) |rpc_decl, idx| {
            routes[numRoutes] = parseRouteFromSpec(ServiceSpec, service_impl, rpc_decl, idx);
            numRoutes += 1;
        }
    }

    // zor server
    const routes_final: [numRoutes]Route = routes[0..numRoutes].*;
    return Server(@TypeOf(impl)).init(&routes_final, impl);
}

test "test initServer" {
    const ApiSpec = struct {
        pub const ParityService = struct {
            pub fn isEven(_: i32) void {
                unreachable;
            }
        };
    };

    const ParityServiceImpl = struct {
        const _std = @import("std");

        pub fn isEven(operand: i32) void {
            _std.debug.print("Yay! it works!, also {}", .{operand});
        }
    };

    const server = comptime ParseServerFromSpec(ApiSpec, .{
        .ParityService = ParityServiceImpl,
    });

    const isEvenMessage = struct {
        rpcId: u8 = 0,
        params: struct { i32 } = .{2},
    }{};

    server.handleRPC(isEvenMessage);
}
