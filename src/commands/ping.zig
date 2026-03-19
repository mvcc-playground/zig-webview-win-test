const std = @import("std");

pub const name = "ping";

pub const Request = struct {
    message: []const u8 = "hello from web",
};

pub const Response = struct {
    command: []const u8 = "ping",
    echoed: []const u8,
    timestamp_ms: i64,
};

pub fn handle(req: Request) Response {
    const message = if (req.message.len == 0) "hello from web" else req.message;
    return .{
        .command = name,
        .echoed = message,
        .timestamp_ms = std.time.milliTimestamp(),
    };
}
