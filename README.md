# zor

> RPC (Remote Procedure Call) framework for zig.

## Overview
`zor` is a RPC framework for zig. Goal with this project is to:
- Provide an ergonomic interface.
- Compile time checking for parameter types.
- Minimizing runtime rpc handling overhead.

Most of this is acheived using zig's `comptime`.

## Usage

To use `zor`, first define an `api.zig` that both the client and server will use. 
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
    
    const server = comptime zor.initServer(api, .{
        .UserService = UserServiceImpl,
    })
    server.serve(io, arena, "0.0.0.0", 8080);

// ... snipped 
```

Usage on the client:
```zig
const api = @import("api");

// ... snipped

    const client = zor.initClient(api)
    try client.connect(io, "0.0.0.0", 8000);

    const user = api.UserService.User {
        .username = getUsername(),
        .encryptedPassword = getEncryptedPassword(),
    };

    const login_successful = client.call(api.UserService.Login, .{ io, gpa, user}) catch |err| {
        // zor error handling (rpc framework errors)
    };
    try login_successful catch |err| {
        // rpc error handling (LoginError in this case)
    };


// ... snipped
```

## Work in Progress
- Handling pointer, slice & nested struct types.
- Connection multiplexing.
- Better Api Spec handling.
- Better compile time errors & error handling.
