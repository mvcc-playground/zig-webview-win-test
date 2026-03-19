const std = @import("std");
const ping = @import("ping.zig");

pub const CommandSpec = struct {
    name: []const u8,
    request_ts: []const u8,
    response_ts: []const u8,
};

pub const specs = [_]CommandSpec{
    .{
        .name = "ping",
        .request_ts = "{ message?: string }",
        .response_ts = "{ command: 'ping'; echoed: string; timestamp_ms: number }",
    },
};

pub fn dispatch(allocator: std.mem.Allocator, command: []const u8, payload: std.json.Value) ![]u8 {
    if (std.mem.eql(u8, command, "ping")) {
        const req = parsePingRequest(payload);
        const res = ping.handle(req);
        return jsonAlloc(allocator, .{
            .ok = true,
            .data = .{
                .command = "ping",
                .echoed = res.echoed,
                .timestamp_ms = res.timestamp_ms,
            },
        });
    }

    return jsonAlloc(allocator, .{
        .ok = false,
        .@"error" = "unknown_command",
        .details = command,
    });
}

fn parsePingRequest(payload: std.json.Value) ping.Request {
    var req: ping.Request = .{};
    switch (payload) {
        .object => |obj| {
            if (obj.get("message")) |msg_val| {
                if (msg_val == .string and msg_val.string.len > 0) {
                    req.message = msg_val.string;
                }
            }
        },
        else => {},
    }
    return req;
}

fn jsonAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    return std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
}
