pub const SumOutput = struct {
    command: []const u8 = "sum",
    result: i64,
};

pub fn sum(a: i64, b: i64) SumOutput {
    return .{
        .command = "sum",
        .result = a + b,
    };
}

pub const commands = .{
    .sum = sum,
};

pub const command_meta = .{
    .sum = .{
        .arg_names = .{ "a", "b" },
    },
};
