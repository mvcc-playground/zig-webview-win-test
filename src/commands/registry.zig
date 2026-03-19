const std = @import("std");
const registered = .{
    // @commands:start
    @import("ping.zig"),
    @import("sum.zig"),
    @import("echo.zig"),
    @import("health.zig"),
        @import("multiplication.zig"),
// @commands:end
};

pub const CommandSpec = struct {
    name: []const u8,
    Request: type,
    Response: type,
    invoke: *const fn (allocator: std.mem.Allocator, payload: std.json.Value) anyerror![]u8,
};

pub const specs = blk: {
    var out: [registered.len]CommandSpec = undefined;
    for (registered, 0..) |command_mod, i| {
        out[i] = makeSpec(command_mod);
    }
    break :blk out;
};

pub fn dispatch(allocator: std.mem.Allocator, command: []const u8, payload: std.json.Value) ![]u8 {
    inline for (specs) |spec| {
        if (std.mem.eql(u8, command, spec.name)) {
            return spec.invoke(allocator, payload);
        }
    }

    return jsonAlloc(allocator, .{
        .ok = false,
        .@"error" = "unknown_command",
        .details = command,
    });
}

fn makeSpec(comptime Command: type) CommandSpec {
    return .{
        .name = Command.name,
        .Request = Command.Request,
        .Response = Command.Response,
        .invoke = makeInvoke(Command),
    };
}

fn makeInvoke(comptime Command: type) *const fn (allocator: std.mem.Allocator, payload: std.json.Value) anyerror![]u8 {
    return struct {
        fn invoke(allocator: std.mem.Allocator, payload: std.json.Value) ![]u8 {
            const req = try parsePayload(allocator, Command.Request, payload);
            const res: Command.Response = Command.handle(req);
            return jsonAlloc(allocator, .{
                .ok = true,
                .data = res,
            });
        }
    }.invoke;
}

fn parsePayload(allocator: std.mem.Allocator, comptime T: type, payload: std.json.Value) !T {
    const payload_json = try std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(payload, .{})});
    return std.json.parseFromSliceLeaky(T, allocator, payload_json, .{
        .ignore_unknown_fields = true,
    });
}

pub fn jsonAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    return std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
}
