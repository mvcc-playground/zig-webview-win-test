pub const name = "health";

pub const Request = struct {};

pub const Response = struct {
    command: []const u8 = name,
    ok: bool,
    service: []const u8,
};

pub fn handle(_: Request) Response {
    return .{
        .command = name,
        .ok = true,
        .service = "zig-mini-runtime",
    };
}
