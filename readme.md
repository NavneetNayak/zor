# zor

> RPC framework for zig.

## Overview & Usage
zor is a RPC framework for zig, it provides a ergonomic interface and operates at low latency. 

To use zor, first define an `api.zig` that both the client and server will use. 
```zig
pub const UserService = struct {
    pub const User = struct {
        username: []u8,
        encryptedPassword: []u8,
    };

    pub const LoginError = error {
        UserDoesNotExist,
        IncorrectPassword,
    };

    pub const UserError = error {
        NotLoggedIn,
    };

    pub fn Login (_: User) LoginError!void { unreachable; }
    pub fn Logout (_: User) !void { unreachable; }
    pub fn GetEmail (_: User) UserError![]u8 { unreachable; }
};
```

Usage on the server:
```zig
const api = @import("api")

// Actual implementations
const us = api.UserService;
const UserServiceImpl = struct {
    fn Login(user: us.User) us.LoginError!void {
        // impl 
    }

    fn Logout(user: us.User) !void {
        // impl 
    }

    fn GetEmail(user: us.User) us.UserError![]u8 {
        // impl
    }
};

// ... snipped 
    
    const server = zor.initServer(api, .{
        .UserService = UserServiceImpl,
    })

    server.serve(io, gpa);

// ... snipped 
```

Usage on the client:
```zig
const api = @import("api");

// ... snipped

    const client = zor.initClient(api)

    const user = api.UserService.User {
        .username = getUsername(),
        .encryptedPassword = getEncryptedPassword(),
    };

    client.call(api.UserService.Login, .{ io, gpa, user}) catch |err| {
        // error handling
    }

// ... snipped
```

