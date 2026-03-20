const std = @import("std");

pub const Input = struct {
    message: []const u8 = "hello from web",
};

pub const Output = struct {
    command: []const u8 = "ping",
    echoed: []const u8,
    timestamp_ms: i64,
};

pub fn ping(input: Input) Output {
    const message = if (input.message.len == 0) "hello from web" else input.message;
    return .{
        .command = "ping",
        .echoed = message,
        .timestamp_ms = std.time.milliTimestamp(),
    };
}

pub const commands = .{
    .ping = ping,
};
