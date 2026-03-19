pub const name = "multiplication";

pub const Request = struct {
    first: i32 = 0,
    second: i32 = 0,
};

pub const Response = struct {
    command: []const u8 = name,
    result: i32,
};

pub fn handle(req: Request) Response {
    return .{
        .command = name,
        .result = req.first * req.second,
    };
}
