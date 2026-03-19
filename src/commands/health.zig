pub const Output = struct {
    command: []const u8 = "health",
    ok: bool,
    service: []const u8,
};

pub fn health() Output {
    return .{
        .command = "health",
        .ok = true,
        .service = "zig-mini-runtime",
    };
}

pub const commands = .{
    .health = health,
};
