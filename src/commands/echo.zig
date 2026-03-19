pub const Input = struct {
    text: []const u8 = "hello",
};

pub const Output = struct {
    command: []const u8 = "echo",
    value: []const u8,
    length: usize,
};

pub fn echo(input: Input) Output {
    return .{
        .command = "echo",
        .value = input.text,
        .length = input.text.len,
    };
}

pub const commands = .{
    .echo = echo,
};
