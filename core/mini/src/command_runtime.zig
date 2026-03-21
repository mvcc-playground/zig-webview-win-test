const std = @import("std");

pub const NativeFailure = struct {
    code: []const u8,
    message: []const u8,
    details: ?[]const u8 = null,
};

pub const DispatchResult = union(enum) {
    success: []u8,
    failure: NativeFailure,
};

pub const CommandSpec = struct {
    name: []const u8,
    Fn: type,
    ArgsTuple: type,
    ReturnType: type,
    invoke: *const fn (allocator: std.mem.Allocator, args: []const std.json.Value) anyerror!DispatchResult,
};

pub fn makeSpecs(comptime app_commands: type) [totalCommandCount(app_commands)]CommandSpec {
    const count = totalCommandCount(app_commands);
    var out: [count]CommandSpec = undefined;
    var idx: usize = 0;
    inline for (app_commands.registered_modules) |module| {
        const cmd_info = @typeInfo(@TypeOf(module.commands)).@"struct";
        inline for (cmd_info.fields) |field| {
            const fn_value = @field(module.commands, field.name);
            out[idx] = makeSpec(field.name, fn_value);
            idx += 1;
        }
    }
    return out;
}

pub fn dispatch(comptime app_commands: type, allocator: std.mem.Allocator, command: []const u8, args: []const std.json.Value) !DispatchResult {
    inline for (makeSpecs(app_commands)) |spec| {
        if (std.mem.eql(u8, command, spec.name)) {
            return spec.invoke(allocator, args);
        }
    }
    return failure("unknown_command", "Command not found", command);
}

pub fn jsonAlloc(allocator: std.mem.Allocator, value: anytype) ![]u8 {
    return std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
}

fn totalCommandCount(comptime app_commands: type) usize {
    var n: usize = 0;
    inline for (app_commands.registered_modules) |module| {
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
        .ReturnType = unwrapErrorUnionPayload(raw_output),
        .invoke = makeInvoke(command_name, func),
    };
}

fn makeInvoke(
    comptime command_name: []const u8,
    comptime func: anytype,
) *const fn (allocator: std.mem.Allocator, args: []const std.json.Value) anyerror!DispatchResult {
    return struct {
        fn invoke(allocator: std.mem.Allocator, args: []const std.json.Value) !DispatchResult {
            const Fn = @TypeOf(func);
            const ArgsTuple = std.meta.ArgsTuple(Fn);
            const fn_info = @typeInfo(Fn).@"fn";
            const raw_output = fn_info.return_type orelse @compileError("command must have return type");

            var parsed_args: ArgsTuple = undefined;
            if (comptime isSingleStructArg(Fn)) {
                if (args.len > 1) {
                    return failure("invalid_args", "Expected a single JSON object argument", command_name);
                }
                const only = fn_info.params[0].type orelse @compileError("anytype parameters are not supported");
                const arg_value: std.json.Value = if (args.len == 0) .{ .null = {} } else args[0];
                parsed_args[0] = parseJsonValue(allocator, only, arg_value) catch |err| {
                    return failure("invalid_args", "Failed to parse object input", @errorName(err));
                };
            } else if (fn_info.params.len == 0) {
                if (args.len != 0) {
                    return failure("invalid_arity", "This command does not accept arguments", command_name);
                }
            } else {
                if (args.len != fn_info.params.len) {
                    return failure("invalid_arity", "Argument count does not match command signature", command_name);
                }
                inline for (fn_info.params, 0..) |param, i| {
                    const ParamT = param.type orelse @compileError("anytype parameters are not supported");
                    parsed_args[i] = parseJsonValue(allocator, ParamT, args[i]) catch |err| {
                        return failure("invalid_args", "Failed to parse positional argument", @errorName(err));
                    };
                }
            }

            if (comptime isErrorUnion(raw_output)) {
                const out = @call(.auto, func, parsed_args) catch |err| {
                    return failure("command_error", "Command returned an unhandled error", @errorName(err));
                };
                return .{ .success = try jsonAlloc(allocator, out) };
            }

            const out = @call(.auto, func, parsed_args);
            return .{ .success = try jsonAlloc(allocator, out) };
        }
    }.invoke;
}

fn parseJsonValue(allocator: std.mem.Allocator, comptime T: type, value: std.json.Value) !T {
    const input_json = try std.fmt.allocPrint(allocator, "{f}", .{std.json.fmt(value, .{})});
    return std.json.parseFromSliceLeaky(T, allocator, input_json, .{
        .ignore_unknown_fields = true,
    });
}

fn failure(code: []const u8, message: []const u8, details: ?[]const u8) DispatchResult {
    return .{
        .failure = .{
            .code = code,
            .message = message,
            .details = details,
        },
    };
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

test "dispatch returns object command result directly" {
    const math_module = struct {
        pub const commands = .{
            .soma = struct {
                const Input = struct { input_a: i32, input_b: i32 };
                const Output = struct { result: i32 };
                pub fn soma(input: Input) Output {
                    return .{ .result = input.input_a + input.input_b };
                }
            }.soma,
        };
    };
    const app_commands = struct {
        pub const registered_modules = .{math_module};
    };

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

    const out = try dispatch(app_commands, allocator, "soma", args[0..]);
    switch (out) {
        .failure => return error.TestUnexpectedResult,
        .success => |json| {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
            defer parsed.deinit();
            try std.testing.expect(parsed.value == .object);
            const result = parsed.value.object.get("result") orelse return error.TestUnexpectedResult;
            try std.testing.expect(result == .integer);
            try std.testing.expectEqual(@as(i64, 11), result.integer);
        },
    }
}

test "dispatch returns scalar command result directly" {
    const scalar_module = struct {
        pub const commands = .{
            .sub = struct {
                pub fn sub(a: i32, b: i32) i32 {
                    return a - b;
                }
            }.sub,
        };
    };
    const app_commands = struct {
        pub const registered_modules = .{scalar_module};
    };

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = [_]std.json.Value{ .{ .integer = 21 }, .{ .integer = 12 } };
    const out = try dispatch(app_commands, allocator, "sub", args[0..]);
    switch (out) {
        .failure => return error.TestUnexpectedResult,
        .success => |json| {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
            defer parsed.deinit();
            try std.testing.expect(parsed.value == .integer);
            try std.testing.expectEqual(@as(i64, 9), parsed.value.integer);
        },
    }
}

test "dispatch returns structured failure when arity is invalid" {
    const scalar_module = struct {
        pub const commands = .{
            .mul = struct {
                pub fn mul(a: i32, b: i32) i32 {
                    return a * b;
                }
            }.mul,
        };
    };
    const app_commands = struct {
        pub const registered_modules = .{scalar_module};
    };

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = [_]std.json.Value{.{ .integer = 12 }};
    const out = try dispatch(app_commands, allocator, "mul", args[0..]);
    switch (out) {
        .success => return error.TestUnexpectedResult,
        .failure => |err| {
            try std.testing.expectEqualStrings("invalid_arity", err.code);
            try std.testing.expectEqualStrings("Argument count does not match command signature", err.message);
        },
    }
}

test "dispatch serializes tagged union return for domain results" {
    const identity_module = struct {
        const Result = union(enum) {
            text: []const u8,
            @"error": struct { message: []const u8 },
        };

        pub const commands = .{
            .getFullName = struct {
                pub fn getFullName(last_name: []const u8) Result {
                    if (std.mem.eql(u8, last_name, "xxx")) {
                        return .{ .@"error" = .{ .message = "blocked" } };
                    }
                    return .{ .text = last_name };
                }
            }.getFullName,
        };
    };
    const app_commands = struct {
        pub const registered_modules = .{identity_module};
    };

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = [_]std.json.Value{.{ .string = "xxx" }};
    const out = try dispatch(app_commands, allocator, "getFullName", args[0..]);
    switch (out) {
        .failure => return error.TestUnexpectedResult,
        .success => |json| {
            const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json, .{});
            defer parsed.deinit();
            const result = parsed.value.object.get("error") orelse return error.TestUnexpectedResult;
            const message = result.object.get("message") orelse return error.TestUnexpectedResult;
            try std.testing.expectEqualStrings("blocked", message.string);
        },
    }
}
