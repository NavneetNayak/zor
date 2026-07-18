const std = @import("std");

const zor = @import("zor");
const api = @import("api");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    const client = zor.initClient(api);

    const ms = api.MathService;

    const vector = ms.Vecf32{
        .x = 1.0,
        .y = 2.5,
    };
    const scalar = 10;

    var future = io.async(client.call, .{
        api.multiplyi32s,
        io,
        gpa,
        vector,
        scalar,
    });
    try future.await(io);
}
