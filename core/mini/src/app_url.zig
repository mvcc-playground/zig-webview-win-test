const std = @import("std");
const build_options = @import("build_options");

pub fn resolve(allocator: std.mem.Allocator) ![:0]u8 {
    if (try envUrl(allocator, "FRONTEND_URL")) |url| return url;
    if (build_options.frontend_url) |url| return try dupZ(allocator, url);

    if (try envUrl(allocator, "FRONTEND_DIST")) |dist_path| {
        defer allocator.free(dist_path);
        return htmlFileUrl(allocator, dist_path);
    }

    return htmlFileUrl(allocator, build_options.frontend_dist);
}

fn envUrl(allocator: std.mem.Allocator, name: []const u8) !?[:0]u8 {
    const value = std.process.getEnvVarOwned(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return null,
        else => return err,
    };
    defer allocator.free(value);
    return try dupZ(allocator, value);
}

pub fn dupZ(allocator: std.mem.Allocator, value: []const u8) ![:0]u8 {
    var out = try allocator.alloc(u8, value.len + 1);
    @memcpy(out[0..value.len], value);
    out[value.len] = 0;
    return out[0..value.len :0];
}

fn htmlFileUrl(allocator: std.mem.Allocator, rel_path: []const u8) ![:0]u8 {
    const abs_path = std.fs.cwd().realpathAlloc(allocator, rel_path) catch |err| switch (err) {
        error.FileNotFound => return error.FrontendEntryNotFound,
        else => return err,
    };
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
