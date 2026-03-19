const std = @import("std");

pub const Request = struct {
    message: []const u8 = "hello from web",
};

pub const Response = struct {
    echoed: []const u8,
    timestamp_ms: i64,
};

pub fn handle(req: Request) Response {
    return .{
        .echoed = req.message,
        .timestamp_ms = std.time.milliTimestamp(),
    };
}
