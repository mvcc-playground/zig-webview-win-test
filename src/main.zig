const std = @import("std");
const commands = @import("commands/mod.zig");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa_state.deinit();
    }
    const allocator = gpa_state.allocator();

    const url = try htmlFileUrl(allocator, "web/index.html");
    defer allocator.free(url);

    const exit_code = mini_webview_run(url.ptr);
    if (exit_code != 0) {
        return error.WebviewRunFailed;
    }
}

fn htmlFileUrl(allocator: std.mem.Allocator, rel_path: []const u8) ![:0]u8 {
    const abs_path = try std.fs.cwd().realpathAlloc(allocator, rel_path);
    defer allocator.free(abs_path);

    var normalized = try allocator.alloc(u8, abs_path.len);
    defer allocator.free(normalized);

    for (abs_path, 0..) |ch, i| {
        normalized[i] = if (ch == '\\') '/' else ch;
    }

    const prefix = "file:///";
    const out_len = prefix.len + normalized.len;
    var out = try allocator.alloc(u8, out_len + 1);
    @memcpy(out[0..prefix.len], prefix);
    @memcpy(out[prefix.len..out_len], normalized);
    out[out_len] = 0;
    return out[0..out_len :0];
}

export fn mini_handle_invoke(req_json: [*:0]const u8, out_json: [*]u8, out_len: usize) callconv(.c) c_int {
    const req_slice = std.mem.span(req_json);

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const allocator = arena_state.allocator();

    const parsed = std.json.parseFromSlice(std.json.Value, allocator, req_slice, .{}) catch {
        return writeJson(out_json, out_len, "{\"ok\":false,\"error\":\"invalid_json\"}");
    };
    defer parsed.deinit();

    const arr = switch (parsed.value) {
        .array => |a| a,
        else => return writeJson(out_json, out_len, "{\"ok\":false,\"error\":\"bad_request_shape\"}"),
    };

    if (arr.items.len == 0 or arr.items[0] != .string) {
        return writeJson(out_json, out_len, "{\"ok\":false,\"error\":\"missing_command\"}");
    }

    const command = arr.items[0].string;
    const payload: std.json.Value = if (arr.items.len > 1) arr.items[1] else .{ .null = {} };

    const result = commands.dispatch(allocator, command, payload) catch {
        return writeJson(out_json, out_len, "{\"ok\":false,\"error\":\"dispatch_failed\"}");
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
