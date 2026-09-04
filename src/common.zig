const std = @import("std");
const cprint = std.fmt.comptimePrint;

pub const ZorRpcError = error{
    InvalidMethod,
};

// Support upto maxRoutes unique RPCs
pub const maxRoutes = 4096;

pub const RouteId = enum(u16) { _ };

pub fn RouteSpec(
    comptime RpcFn: type,
    comptime service_name: []const u8,
    comptime rpc_name: []const u8,
    comptime id_u16: u16,
) type {
    return struct {
        // routes are indexed by array idx, but we store id for easier debugging
        pub const id: RouteId = @enumFromInt(id_u16);

        pub const _service_name = service_name;
        pub const _rpc_name = rpc_name;

        pub const _RpcFn = RpcFn;

        pub const Params = reflected.@"0";
        pub const Ret = reflected.@"1";

        const reflected = blk: {
            const info = @typeInfo(RpcFn);
            if (info != .@"fn")
                @compileError(cprint("{s} Not a function type!\n", .{rpc_name}));

            const fn_info = info.@"fn";
            if (fn_info.is_var_args)
                @compileError(cprint("{s} | RPCs with variable arguments are not supported\n", .{rpc_name}));

            var arg_field_list: [fn_info.params.len]type = undefined;
            for (fn_info.params, 0..) |arg, idx| {
                const Type = arg.type orelse
                    @compileError(cprint("{s} | RPCs with arguments of `anytype` are not supported\n", .{rpc_name}));

                arg_field_list[idx] = Type;
            }

            const _Ret = fn_info.return_type orelse
                @compileError(cprint("{s} | RPCs must have a concrete return type\n", .{rpc_name}));

            break :blk .{
                std.meta.Tuple(&arg_field_list),
                _Ret,
            };
        };
    };
}

pub fn parseRouteSpecs(comptime ApiSpec: type) []const type {
    comptime var buf: [maxRoutes]type = undefined;
    comptime var RouteSpecs = std.ArrayListUnmanaged(type).initBuffer(&buf);

    for (std.meta.declarations(ApiSpec)) |ServiceDecl| {
        const ServiceSpec = @field(ApiSpec, ServiceDecl.name);

        for (std.meta.declarations(ServiceSpec)) |RpcDecl| {
            const rpc_name = RpcDecl.name;
            const RpcSpec = @field(ServiceSpec, rpc_name);

            // Only functions allowed
            if (@TypeOf(RpcSpec) == type) continue;

            RouteSpecs.appendAssumeCapacity(
                RouteSpec(@TypeOf(RpcSpec), ServiceDecl.name, rpc_name, @intCast(RouteSpecs.items.len)),
            );
        }
    }

    const RouteSpecsFinal: [RouteSpecs.items.len]type = RouteSpecs.items[0..RouteSpecs.items.len].*;
    return &RouteSpecsFinal;
}
