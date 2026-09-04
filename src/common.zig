const std = @import("std");
const cprint = std.fmt.comptimePrint;

pub const ZorRpcError = error{
    InvalidMethod,
};

// Support upto maxRoutes unique RPCs
pub const maxRoutes = 4096;

pub const RouteId = enum(u16) { _ };

pub fn Route(
    comptime id_u16: u16,
    comptime rpc_fn: anytype,
    rpc_name: []const u8,
) type {
    return struct {
        // routes are indexed by array idx, but we store id for easier debugging
        pub const id: RouteId = @enumFromInt(id_u16);

        pub const _rpc_fn = rpc_fn;
        pub const RpcFn = @TypeOf(rpc_fn);

        pub const Params = reflected.@"0";
        pub const Ret = reflected.@"1";

        const reflected = blk: {
            const info = @typeInfo(RpcFn);
            if (info != .@"fn")
                @compileError(cprint("{} Not a function type!\n", .{rpc_name}));

            const fn_info = info.@"fn";
            if (fn_info.is_var_args)
                @compileError(cprint("{} | RPCs with variable arguments are not supported\n", .{rpc_name}));

            var arg_field_list: [fn_info.params.len]type = undefined;
            for (fn_info.params, 0..) |arg, idx| {
                const Type = arg.type orelse
                    @compileError(cprint("{} | RPCs with arguments of `anytype` are not supported\n", .{rpc_name}));

                arg_field_list[idx] = Type;
            }

            break :blk .{
                std.meta.Tuple(&arg_field_list),
                fn_info.return_type,
            };
        };
    };
}

fn parseRouteFromSpec(
    comptime ServiceSpec: type,
    comptime service_impl: anytype,
    comptime rpc_decl: anytype,
    comptime id_u16: u8,
) type {
    const rpc_name = rpc_decl.name;
    const RpcSpec = @field(ServiceSpec, rpc_name);

    const rpc_impl =
        if (@hasDecl(service_impl, rpc_name))
            @field(service_impl, rpc_name)
        else
            @compileError(cprint("No rpc implementation for {s} provided.", .{rpc_name}));

    if (@TypeOf(RpcSpec) != @TypeOf(rpc_impl))
        @compileError(cprint("Rpc signature for {s} doesn't match impl", .{rpc_name}));

    return Route(id_u16, rpc_impl, rpc_name);
}

pub fn parseRoutesFromSpec(
    comptime ApiSpec: type,
    comptime impl: anytype,
) []const type {
    comptime var buf: [maxRoutes]type = undefined;
    comptime var routes = std.ArrayListUnmanaged(type).initBuffer(&buf);

    const service_decls = @typeInfo(ApiSpec).@"struct".decls;

    // validate and parse routes from spec and impl
    for (service_decls) |service_decl| {
        const service_name = service_decl.name;
        const ServiceSpec = @field(ApiSpec, service_name);

        const service_impl =
            if (@hasField(@TypeOf(impl), service_name))
                @field(impl, service_name)
            else
                @compileError(cprint("No implementation provided for service: {s}", .{service_name}));

        const rpc_decls = @typeInfo(ServiceSpec).@"struct".decls;

        for (rpc_decls) |rpc_decl| {
            routes.appendAssumeCapacity(
                parseRouteFromSpec(ServiceSpec, service_impl, rpc_decl, @intCast(routes.items.len)),
            );
        }
    }

    const routes_final: [routes.items.len]type = routes.items[0..routes.items.len].*;
    return &routes_final;
}
