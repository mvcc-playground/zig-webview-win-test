const std = @import("std");
const app_url = @import("app_url.zig");
const commands = @import("commands/mod.zig");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa_state.deinit();
    }
    const allocator = gpa_state.allocator();

    const url = app_url.resolve(allocator) catch |err| {
        if (err == error.FrontendEntryNotFound) {
            std.log.err("frontend entry not found. Run `mise build-frontend` or set FRONTEND_URL for dev.", .{});
        }
        return err;
    };
    defer allocator.free(url);

    const exit_code = mini_webview_run(url.ptr);
    if (exit_code != 0) {
        return error.WebviewRunFailed;
    }
}

export fn mini_handle_invoke(req_json: [*:0]const u8, out_json: [*]u8, out_len: usize) callconv(.c) c_int {
    const req_slice = std.mem.span(req_json);

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const allocator = arena_state.allocator();

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, req_slice, .{}) catch {
        return writeFailure(out_json, out_len, .{
            .code = "invalid_json",
            .message = "Request is not valid JSON",
        });
    };
    defer parsed.deinit();

    const arr = switch (parsed.value) {
        .array => |a| a,
        else => return writeFailure(out_json, out_len, .{
            .code = "bad_request_shape",
            .message = "Expected invoke argument array",
        }),
    };

    if (arr.items.len == 0 or arr.items[0] != .string) {
        return writeFailure(out_json, out_len, .{
            .code = "missing_command",
            .message = "First invoke argument must be command name",
        });
    }

    const command = arr.items[0].string;
    const args = if (arr.items.len > 1) arr.items[1..] else arr.items[0..0];

    const result = commands.dispatch(allocator, command, args) catch |err| {
        return writeFailure(out_json, out_len, .{
            .code = "dispatch_failed",
            .message = "Native dispatch failed",
            .details = @errorName(err),
        });
    };
    return switch (result) {
        .success => |json| writeJson(out_json, out_len, json),
        .failure => |failure| writeFailure(out_json, out_len, failure),
    };
}

fn writeJson(out_json: [*]u8, out_len: usize, msg: []const u8) c_int {
    if (out_len == 0) return 1;
    const max_copy = out_len - 1;
    const n = @min(msg.len, max_copy);
    @memcpy(out_json[0..n], msg[0..n]);
    out_json[n] = 0;
    return 0;
}

fn writeFailure(out_json: [*]u8, out_len: usize, failure: commands.registry.NativeFailure) c_int {
    const msg = std.fmt.allocPrint(std.heap.page_allocator, "{f}", .{std.json.fmt(failure, .{})}) catch {
        return writeJson(out_json, out_len, "{\"code\":\"native_failure\",\"message\":\"Unable to serialize invoke failure\"}");
    };
    defer std.heap.page_allocator.free(msg);
    _ = writeJson(out_json, out_len, msg);
    return 1;
}

extern fn mini_webview_run(start_url: [*:0]const u8) callconv(.c) c_int;
