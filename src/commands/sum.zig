pub const name = "sum";

pub const Request = struct {
    a: i64 = 0,
    b: i64 = 0,
};

pub const Response = struct {
    command: []const u8 = name,
    result: i64,
};

pub fn handle(req: Request) Response {
    return .{
        .command = name,
        .result = req.a + req.b,
    };
}
