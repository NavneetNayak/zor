pub const MathService = struct {
    pub const Vecf32 = struct {
        x: f32,
        y: f32,
    };

    pub fn multiplyf32Vecf32(_: f32, _: Vecf32) Vecf32 {
        unreachable;
    }

    pub const DivisionError = error{
        DivisionByZero,
    };

    pub fn dividei32(_: i32, _: i32) DivisionError!i32 {
        unreachable;
    }
};

pub const ParityService = struct {
    pub fn isEven(_: i32) bool {
        unreachable;
    }
};

pub const TestService = struct {
    pub fn stringTest(_: []const u8) void {
        unreachable;
    }
};
