pub const Output = struct {
    command: []const u8 = "multiplication",
    result: i32,
};

pub fn multiplication(a: i32, b: i32) Output {
    return .{
        .command = "multiplication",
        .result = a * b,
    };
}

pub const commands = .{
    .multiplication = multiplication,
};

pub const command_meta = .{
    .multiplication = .{
        .arg_names = .{ "a", "b" },
    },
};
