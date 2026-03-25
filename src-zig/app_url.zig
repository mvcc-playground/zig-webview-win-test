const std = @import("std");
const build_options = @import("build_options");

pub const Surface = enum {
    minibar,
    control_panel,
};

pub fn resolve(allocator: std.mem.Allocator) ![:0]u8 {
    return resolveSurface(allocator, .minibar);
}

pub fn resolveSurface(allocator: std.mem.Allocator, surface: Surface) ![:0]u8 {
    const html_name = surfaceHtmlName(surface);

    if (try envUrl(allocator, "FRONTEND_URL")) |base_url| {
        defer allocator.free(base_url);
        return try joinUrl(allocator, base_url, html_name);
    }
    if (build_options.frontend_url) |base_url| {
        return try joinUrl(allocator, base_url, html_name);
    }

    if (try envUrl(allocator, "FRONTEND_DIST")) |dist_path| {
        defer allocator.free(dist_path);
        const surface_path = try siblingPath(allocator, dist_path, html_name);
        defer allocator.free(surface_path);
        return htmlFileUrl(allocator, surface_path);
    }

    const default_path = try siblingPath(allocator, build_options.frontend_dist, html_name);
    defer allocator.free(default_path);
    return htmlFileUrl(allocator, default_path);
}

fn envUrl(allocator: std.mem.Allocator, name: []const u8) !?[:0]u8 {
    const value = std.process.getEnvVarOwned(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return null,
        else => return err,
    };
    defer allocator.free(value);
    return try dupZ(allocator, value);
}

fn dupZ(allocator: std.mem.Allocator, value: []const u8) ![:0]u8 {
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

fn surfaceHtmlName(surface: Surface) []const u8 {
    return switch (surface) {
        .minibar => "minibar.html",
        .control_panel => "control-panel.html",
    };
}

fn joinUrl(allocator: std.mem.Allocator, base_url: []const u8, html_name: []const u8) ![:0]u8 {
    const trimmed = std.mem.trimRight(u8, base_url, "/");
    const joined = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ trimmed, html_name });
    defer allocator.free(joined);
    return dupZ(allocator, joined);
}

fn siblingPath(allocator: std.mem.Allocator, any_path: []const u8, html_name: []const u8) ![]u8 {
    if (std.fs.path.dirname(any_path)) |dir| {
        return std.fs.path.join(allocator, &.{ dir, html_name });
    }
    return allocator.dupe(u8, html_name);
}
