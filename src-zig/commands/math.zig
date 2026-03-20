pub const SomaInput = struct {
    input_a: i32 = 0,
    input_b: i32 = 0,
};

pub const SomaOutput = struct {
    command: []const u8 = "soma",
    result: i32,
};

pub fn soma(input: SomaInput) SomaOutput {
    return .{
        .command = "soma",
        .result = input.input_a + input.input_b,
    };
}

pub const InputMultiply = struct {
    left: i32 = 1,
    right: i32 = 1,
};

pub const OutputMultiply = struct {
    command: []const u8 = "multiply",
    result: i32,
};

pub fn multiply(input: InputMultiply) OutputMultiply {
    return .{
        .command = "multiply",
        .result = input.left * input.right,
    };
}

pub fn sub(a: i32, b: i32) i32 {
    return a - b;
}

pub const commands = .{
    .soma = soma,
    .multiply = multiply,
    .sub = sub,
};

pub const command_meta = .{
    .sub = .{
        .arg_names = .{ "a", "b" },
    },
};
