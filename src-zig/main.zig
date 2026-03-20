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
        return writeJson(out_json, out_len, "[null,{\"code\":\"invalid_json\",\"message\":\"Request is not valid JSON\"}]");
    };
    defer parsed.deinit();

    const arr = switch (parsed.value) {
        .array => |a| a,
        else => return writeJson(out_json, out_len, "[null,{\"code\":\"bad_request_shape\",\"message\":\"Expected invoke argument array\"}]"),
    };

    if (arr.items.len == 0 or arr.items[0] != .string) {
        return writeJson(out_json, out_len, "[null,{\"code\":\"missing_command\",\"message\":\"First invoke argument must be command name\"}]");
    }

    const command = arr.items[0].string;
    const args = if (arr.items.len > 1) arr.items[1..] else arr.items[0..0];

    const result = commands.dispatch(allocator, command, args) catch {
        return writeJson(out_json, out_len, "[null,{\"code\":\"dispatch_failed\",\"message\":\"Native dispatch failed\"}]");
    };
    return writeJson(out_json, out_len, result);
}

fn writeJson(out_json: [*]u8, out_len: usize, msg: []const u8) c_int {
    if (out_len == 0) return 1;
    const max_copy = out_len - 1;
    const n = @min(msg.len, max_copy);
    @memcpy(out_json[0..n], msg[0..n]);
    out_json[n] = 0;
    return 0;
}

extern fn mini_webview_run(start_url: [*:0]const u8) callconv(.c) c_int;
