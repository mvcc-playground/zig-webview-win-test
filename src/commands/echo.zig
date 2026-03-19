pub const name = "echo";

pub const Request = struct {
    text: []const u8 = "hello",
};

pub const Response = struct {
    command: []const u8 = name,
    value: []const u8,
    length: usize,
};

pub fn handle(req: Request) Response {
    return .{
        .command = name,
        .value = req.text,
        .length = req.text.len,
    };
}
