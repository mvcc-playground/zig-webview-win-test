const std = @import("std");
const webview = @import("../webview/mod.zig");
const logging = @import("../features/logging/mod.zig");

pub const RuntimeMode = enum {
    native_multi_window,
};

pub const Urls = struct {
    minibar: [:0]const u8,
    control_panel: [:0]const u8,
};

pub const WindowManager = struct {
    urls: Urls,
    mode: RuntimeMode = .native_multi_window,
    control_panel_requested: bool = false,

    pub fn init(urls: Urls) WindowManager {
        return .{ .urls = urls };
    }

    pub fn runMainWindow(self: *WindowManager, logger: *logging.LogService, trace_id: []const u8) !void {
        try logger.write(.{
            .level = .INFO,
            .trace_id = trace_id,
            .module = "window_manager",
            .event = "window_opened",
            .message = "Opening native shell windows (minibar + control panel)",
            .metadata_json = "{\"window_kind\":\"minibar\",\"control_panel_preloaded\":true}",
        });
        try webview.runtime.runShell(self.urls.minibar, self.urls.control_panel, false);
    }

    pub fn openControlPanel(self: *WindowManager, logger: *logging.LogService, trace_id: []const u8) !RuntimeMode {
        self.control_panel_requested = true;
        try webview.runtime.openControlPanel();
        try logger.write(.{
            .level = .INFO,
            .trace_id = trace_id,
            .module = "window_manager",
            .event = "open_control_panel_requested",
            .message = "Control panel opened in native secondary window",
            .metadata_json = "{\"window_kind\":\"control_panel\",\"fallback\":false}",
        });
        return self.mode;
    }
};
