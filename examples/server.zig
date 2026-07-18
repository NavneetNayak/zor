const std = @import("std");

const zor = @import("zor");
const api = @import("api");

const ms = api.MathService;
const MathServiceImpl = struct {
    fn multiplyf32Vecf32(scalar: f32, vector: ms.Vecf32) !ms.Vecf32 {
        return vector * scalar;
    }

    fn multiplyi32s(operandOne: i32, operandTwo: i32) !i32 {
        return operandOne * operandTwo;
    }

    fn dividei32s(dividend: i32, divisor: i32) ms.DivisionError!i32 {
        if (divisor == 0) {
            return ms.DivisionByZero;
        }

        return dividend / divisor;
    }
};

const ps = api.ParityService;
const ParityServiceImpl = struct {
    fn isEven(operand: i32) !bool {
        return operand % 2;
    }
};

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    const server = zor.initServer(api);
    server.setImpl(.{
        .MathService = MathServiceImpl,
        .ParityService = ParityServiceImpl,
    });

    server.serve(io, gpa);
}
