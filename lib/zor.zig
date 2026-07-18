const std = @import("std");

pub fn parseApiSpec(apiSpec: type) !type {
    const servicesInfo = switch (@typeInfo(apiSpec)) {
        .@"struct" => |info| info,
        else => @compileError("Api Spec must be a struct"),
    };

    var implFieldNames: [servicesInfo.field_names.len]u8 = undefined;
    var implFieldTypes: [servicesInfo.field_names.len]type = undefined;

    for (servicesInfo.field_names, servicesInfo.field_types, 0..) |serviceName, serviceType, idx| {
        switch (@typeInfo(serviceType)) {
            .@"struct" => {},
            else => @compileError("Service " + serviceName + " must be a struct"),
        }

        implFieldNames[idx] = serviceName;
        implFieldTypes[idx] = parseServiceRpcs(serviceType);
    }

    return @Struct(
        .auto,
        null,
        &implFieldNames,
        &implFieldTypes,
        &@splat(.{}),
    );
}

pub fn parseServiceRpcs(_: type) !type {
    unreachable;
}
