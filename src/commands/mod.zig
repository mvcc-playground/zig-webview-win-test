const std = @import("std");
const ping = @import("ping.zig");

const JsonValue = std.json.Value;

pub fn dispatch(allocator: std.mem.Allocator, command: []const u8, payload: JsonValue) ![]u8 {
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

fn parsePingRequest(payload: JsonValue) ping.Request {
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
