const server = @import("server.zig");
const client = @import("client.zig");

pub fn initServer(ApiSpec: type, comptime ApiImpl: type) server.Server(ApiSpec, ApiImpl) {
    return server.Server(ApiSpec, ApiImpl){};
}

pub fn initClient(ApiSpec: type) client.Client(ApiSpec) {
    return client.Client(ApiSpec){};
}
