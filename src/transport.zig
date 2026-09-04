const std = @import("std");
const cprint = std.fmt.comptimePrint;

const common = @import("common.zig");

pub const recvBufferSize = 4096;

pub const ZorSerializationError = error{
    MissingField,
    AllocationError,
};

pub const ZorDeserializationError = error{
    MangledBytes,
};

pub const ZorTransportError = ZorSerializationError || ZorDeserializationError;

pub const MessageType = enum(u8) {
    Request,
    Response,
};

pub const MessageHeader = extern struct {
    message_type: MessageType,
    rpc_id_u16: u16,
    message_len: u32 = 0,
};

pub const MessageBody = struct {
    const Self = @This();

    bytes: []u8 = &.{},

    // TODO: handle slices, pointers & nested structs
    pub fn deserializeMessageBody(self: *const Self, comptime Type: type) Type {
        if (@typeInfo(Type) == .@"struct") {
            var res: Type = undefined;
            var offset: usize = 0;

            inline for (std.meta.fields(Type)) |field| {
                const size = @sizeOf(field.type);

                const field_bytes = self.bytes[offset..][0..size];
                @field(res, field.name) = std.mem.bytesToValue(field.type, field_bytes);

                offset += size;
            }

            return res;
        } else {
            return std.mem.bytesToValue(Type, self.bytes);
        }

        return std.mem.bytesToValue(Type, self.bytes[0..@sizeOf(Type)]);
    }

    // TODO: handle slices, pointers & nested structs
    pub fn serializeMessageBody(
        arena: std.mem.Allocator,
        any: anytype,
        Type: type,
    ) !Self {
        // must coerce to handle comptime_int, comptime_float etc...
        const typed: Type = any;
        var bytes: std.ArrayList(u8) = .empty;

        if (@typeInfo(Type) == .@"struct") {
            inline for (std.meta.fields(Type)) |field| {
                const field_val = @field(typed, field.name);
                const field_bytes = std.mem.toBytes(field_val);

                bytes.appendSlice(arena, &field_bytes) catch return ZorTransportError.AllocationError;
            }
        } else {
            const val_bytes = std.mem.toBytes(typed);
            bytes.appendSlice(arena, &val_bytes) catch return ZorTransportError.AllocationError;
        }

        return Self{
            .bytes = bytes.toOwnedSlice(arena) catch return ZorTransportError.AllocationError,
        };
    }
};

pub fn writeMessage(
    writer: *std.Io.Writer,
    message_type: MessageType,
    rpc_id_u16: u16,
    message_body: MessageBody,
) !void {
    const header = MessageHeader{
        .message_type = message_type, // Single byte no need to change endianness
        .rpc_id_u16 = std.mem.nativeToBig(u16, rpc_id_u16),
        .message_len = std.mem.nativeToBig(u32, @intCast(message_body.bytes.len)),
    };

    try writer.writeAll(std.mem.asBytes(&header));
    try writer.writeAll(message_body.bytes);
}

pub fn readMessage(arena: std.mem.Allocator, reader: *std.Io.Reader) !struct { MessageHeader, MessageBody } {
    const header = try reader.takeStruct(MessageHeader, std.builtin.Endian.big);

    const message_bytes = try arena.alloc(u8, header.message_len);
    try reader.readSliceAll(message_bytes);

    return .{ header, MessageBody{ .bytes = message_bytes } };
}
