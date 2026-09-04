const std = @import("std");
const cprint = std.fmt.comptimePrint;

pub const RawMessage = struct {
    bytes: []const u8,

    // pub fn decode(self: RawMessage, comptime Params: type) Params {}
};
