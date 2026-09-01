pub const MathService = struct {
    pub const Vecf32 = struct {
        x: f32,
        y: f32,
    };

    pub fn multipyf32Vecf32(_: f32, _: Vecf32) !Vecf32      { unreachable; }


    pub fn multiplyi32s(_: i32, _: i32) !i64                { unreachable; }


    pub const DivisionError = error{
        DivisionByZero,
    };

    pub fn dividei32s(_: i32, _: i32) DivisionError!i32     { unreachable; }
};

pub const ParityService = struct {
    pub fn isEven(_: i32) !bool                             { unreachable; }
};
