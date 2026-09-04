const std = @import("std");
const cprint = std.fmt.comptimePrint;

const common = @import("common.zig");
const transport = @import("transport.zig");

const RawMessage = struct {
    bytes: []const u8,

    pub fn decode(self: RawMessage, comptime Params: type) Params {
        var result: Params = undefined;
        var offset: usize = 0;
        inline for (std.meta.fields(Params)) |field| {
            const size = @sizeOf(field.type);
            const field_bytes = self.bytes[offset..][0..size];
            @field(result, field.name) = std.mem.bytesToValue(field.type, field_bytes);
            offset += size;
        }
        return result;
    }
};

pub const Server = struct {
    const Self = @This();

    routes: []const type,

    pub fn handleRPC(
        comptime self: *const Self,
        rpc_id_u16: u16,
        raw: RawMessage,
        // requestDeserializerFn: std.builtin.Type.Fn,
        // responseSerializerFn: std.builtin.Type.Fn,
    ) common.ZorRpcError!transport.RawMessage {
        // generate static routing
        switch (rpc_id_u16) {
            inline 0...(self.routes.len - 1) => |route_id| {
                const route = self.routes[route_id];

                // const params = requestDeserializerFn(route.Params, raw);
                // const ret = @call(.auto, route._rpc_fn, params);
                // return responseSerializerFn(route.Ret, ret);

                const params = raw.decode(route.Params);
                @call(.auto, route._rpc_fn, params);

                return transport.RawMessage{ .bytes = &std.mem.toBytes(@as(i32, 0)) };
            },
            else => {
                return common.ZorRpcError.InvalidMethod;
            },
        }
    }
};
