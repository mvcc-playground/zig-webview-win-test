const std = @import("std");

pub const registered_modules = .{
    // @modules:start
    @import("ping.zig"),
    @import("sum.zig"),
    @import("echo.zig"),
    @import("health.zig"),
    @import("multiplication.zig"),
    @import("math.zig"),
    // @modules:end
};

pub const CommandSpec = struct {
    name: []const u8,
    Fn: type,
    ArgsTuple: type,
    Output: type,
    invoke: *const fn (allocator: std.mem.Allocator, args: []const std.json.Value) anyerror![]u8,
};

pub const specs = blk: {
    const count = totalCommandCount();
    var out: [count]CommandSpec = undefined;
    var idx: usize = 0;
    for (registered_modules) |module| {
        const cmd_info = @typeInfo(@TypeOf(module.commands)).@"struct";
        for (cmd_info.fields) |field| {
            const fn_value = @field(module.commands, field.name);
            out[idx] = makeSpec(field.name, fn_value);
            idx += 1;
        }
    }
    break :blk out;
};

pub fn dispatch(allocator: std.mem.Allocator, command: []const u8, args: []const std.json.Value) ![]u8 {
    inline for (specs) |spec| {
        if (std.mem.eql(u8, command, spec.name)) {
            return spec.invoke(allocator, args);
        }
    }
    return tupleErr(allocator, "unknown_command", "Command not found", command);
}

pub fn jsonAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    return std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
}

fn totalCommandCount() usize {
    var n: usize = 0;
    inline for (registered_modules) |module| {
        n += @typeInfo(@TypeOf(module.commands)).@"struct".fields.len;
    }
    return n;
}

fn makeSpec(comptime command_name: []const u8, comptime func: anytype) CommandSpec {
    const Fn = @TypeOf(func);
    const fn_info = @typeInfo(Fn).@"fn";
    const raw_output = fn_info.return_type orelse @compileError("command must have a return type");

    return .{
        .name = command_name,
        .Fn = Fn,
        .ArgsTuple = std.meta.ArgsTuple(Fn),
        .Output = unwrapErrorUnionPayload(raw_output),
        .invoke = makeInvoke(command_name, func),
    };
}

fn makeInvoke(
    comptime command_name: []const u8,
    comptime func: anytype,
) *const fn (allocator: std.mem.Allocator, args: []const std.json.Value) anyerror![]u8 {
    return struct {
        fn invoke(allocator: std.mem.Allocator, args: []const std.json.Value) ![]u8 {
            const Fn = @TypeOf(func);
            const ArgsTuple = std.meta.ArgsTuple(Fn);
            const fn_info = @typeInfo(Fn).@"fn";
            const raw_output = fn_info.return_type orelse @compileError("command must have return type");

            var parsed_args: ArgsTuple = undefined;
            if (comptime isSingleStructArg(Fn)) {
                if (args.len > 1) return tupleErr(allocator, "invalid_args", "Expected a single JSON object argument", command_name);
                const only = fn_info.params[0].type orelse @compileError("anytype parameters are not supported");
                const arg_value: std.json.Value = if (args.len == 0) .{ .null = {} } else args[0];
                parsed_args[0] = parseJsonValue(allocator, only, arg_value) catch |err| {
                    return tupleErr(allocator, "invalid_args", "Failed to parse object input", @errorName(err));
                };
            } else if (fn_info.params.len == 0) {
                if (args.len != 0) {
                    return tupleErr(allocator, "invalid_arity", "This command does not accept arguments", command_name);
                }
            } else {
                if (args.len != fn_info.params.len) {
                    return tupleErr(
                        allocator,
                        "invalid_arity",
                        "Argument count does not match command signature",
                        command_name,
                    );
                }
                inline for (fn_info.params, 0..) |param, i| {
                    const ParamT = param.type orelse @compileError("anytype parameters are not supported");
                    parsed_args[i] = parseJsonValue(allocator, ParamT, args[i]) catch |err| {
                        return tupleErr(
                            allocator,
                            "invalid_args",
                            "Failed to parse positional argument",
                            @errorName(err),
                        );
                    };
                }
            }

            if (comptime isErrorUnion(raw_output)) {
                const out = @call(.auto, func, parsed_args) catch |err| {
                    return tupleErr(allocator, "command_error", "Command returned an error", @errorName(err));
                };
                return tupleOk(allocator, out);
            }

            const out = @call(.auto, func, parsed_args);
            return tupleOk(allocator, out);
        }
    }.invoke;
}

fn parseJsonValue(allocator: std.mem.Allocator, comptime T: type, value: std.json.Value) !T {
    const input_json = try std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
    return std.json.parseFromSliceLeaky(T, allocator, input_json, .{
        .ignore_unknown_fields = true,
    });
}

fn tupleOk(allocator: std.mem.Allocator, data: anytype) ![]u8 {
    return jsonAlloc(allocator, .{
        data,
        @as(?InvokeError, null),
    });
}

fn tupleErr(allocator: std.mem.Allocator, code: []const u8, message: []const u8, details: ?[]const u8) ![]u8 {
    return jsonAlloc(allocator, .{
        @as(?std.json.Value, null),
        InvokeError{
            .code = code,
            .message = message,
            .details = details,
        },
    });
}

fn unwrapErrorUnionPayload(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .error_union => |eu| eu.payload,
        else => T,
    };
}

fn isErrorUnion(comptime T: type) bool {
    return @typeInfo(T) == .error_union;
}

fn isSingleStructArg(comptime Fn: type) bool {
    const fn_info = @typeInfo(Fn).@"fn";
    if (fn_info.params.len != 1) return false;
    const only = fn_info.params[0].type orelse @compileError("anytype parameters are not supported");
    return @typeInfo(only) == .@"struct";
}

pub const InvokeError = struct {
    code: []const u8,
    message: []const u8,
    details: ?[]const u8 = null,
};

test "dispatch supports object argument command" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const arg_obj = try std.json.parseFromSliceLeaky(
        std.json.Value,
        allocator,
        "{\"input_a\":7,\"input_b\":4}",
        .{},
    );
    const args = [_]std.json.Value{arg_obj};

    const out = try dispatch(allocator, "soma", args[0..]);
    defer allocator.free(out);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, out, .{});
    defer parsed.deinit();
    try std.testing.expect(parsed.value == .array);
    try std.testing.expect(parsed.value.array.items.len == 2);
    try std.testing.expect(parsed.value.array.items[0] == .object);
    const data = parsed.value.array.items[0].object;
    try std.testing.expect(data.get("result") != null);
    try std.testing.expect(parsed.value.array.items[1] == .null);
}

test "dispatch supports positional arguments command" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = [_]std.json.Value{ .{ .integer = 12 }, .{ .integer = 21 } };

    const out = try dispatch(allocator, "multiplication", args[0..]);
    defer allocator.free(out);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, out, .{});
    defer parsed.deinit();
    try std.testing.expect(parsed.value == .array);
    const data = parsed.value.array.items[0].object;
    const result = data.get("result") orelse return error.TestUnexpectedResult;
    try std.testing.expect(result == .integer);
    try std.testing.expectEqual(@as(i64, 252), result.integer);
    try std.testing.expect(parsed.value.array.items[1] == .null);
}

test "dispatch returns tuple error when arity is invalid" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = [_]std.json.Value{.{ .integer = 12 }};

    const out = try dispatch(allocator, "multiplication", args[0..]);
    defer allocator.free(out);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, out, .{});
    defer parsed.deinit();
    try std.testing.expect(parsed.value == .array);
    try std.testing.expect(parsed.value.array.items[0] == .null);
    try std.testing.expect(parsed.value.array.items[1] == .object);
    const err_obj = parsed.value.array.items[1].object;
    const code = err_obj.get("code") orelse return error.TestUnexpectedResult;
    try std.testing.expect(code == .string);
    try std.testing.expectEqualStrings("invalid_arity", code.string);
}
