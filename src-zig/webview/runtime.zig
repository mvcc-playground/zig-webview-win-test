const std = @import("std");

pub const SizeHint = enum(c_int) {
    none = 0,
    min = 1,
    max = 2,
    fixed = 3,
};

pub const Webview = struct {
    debug: bool,
    title: []const u8 = "zig mini-tauri",
    width: c_int = 980,
    height: c_int = 680,
    hint: SizeHint = .none,
    start_url: ?[:0]const u8 = null,

    pub fn create(debug: bool, window: ?*anyopaque) !Webview {
        if (window != null) return error.ExternalWindowUnsupported;
        return .{ .debug = debug };
    }

    pub fn destroy(self: *Webview) void {
        _ = self;
    }

    pub fn setTitle(self: *Webview, title: []const u8) !void {
        if (title.len == 0) return error.InvalidTitle;
        self.title = title;
    }

    pub fn setSize(self: *Webview, width: c_int, height: c_int, hint: SizeHint) !void {
        if (width <= 0 or height <= 0) return error.InvalidSize;
        self.width = width;
        self.height = height;
        self.hint = hint;
    }

    pub fn navigate(self: *Webview, start_url: [:0]const u8) !void {
        if (start_url.len == 0) return error.InvalidUrl;
        self.start_url = start_url;
    }

    pub fn run(self: *Webview) !void {
        const start_url = self.start_url orelse return error.MissingStartUrl;
        const owned_title = try std.heap.c_allocator.dupeZ(u8, self.title);
        defer std.heap.c_allocator.free(owned_title);

        const exit_code = mini_webview_run_app(
            if (self.debug) 1 else 0,
            owned_title.ptr,
            self.width,
            self.height,
            @intFromEnum(self.hint),
            start_url.ptr,
        );
        if (exit_code != 0) return error.WebviewRunFailed;
    }
};

extern fn mini_webview_run_app(
    debug: c_int,
    title: [*:0]const u8,
    width: c_int,
    height: c_int,
    hint: c_int,
    start_url: [*:0]const u8,
) callconv(.c) c_int;
