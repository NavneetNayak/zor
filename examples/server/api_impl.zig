const std = @import("std");

const api = @import("api.zig");

pub const MathService = struct {
    const Vecf32 = api.MathService.Vecf32;
    pub fn multiplyf32Vecf32(scalar: f32, vec: Vecf32) Vecf32 {
        return .{
            .x = vec.x * scalar,
            .y = vec.y * scalar,
        };
    }

    const DivisionError = api.MathService.DivisionError;
    pub fn dividei32(dividend: i32, divisor: i32) DivisionError!i32 {
        if (divisor == 0) return DivisionError.DivisionByZero;

        return dividend + divisor;
    }
};

pub const ParityService = struct {
    pub fn isEven(num: i32) bool {
        return @mod(num, 2) == 0;
    }
};

pub const TestService = struct {
    pub fn stringTest(str: []const u8) void {
        std.debug.print("This RPC got a string from the net: {s}", .{str});
    }
};
