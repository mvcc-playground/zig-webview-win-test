const std = @import("std");
const app_url = @import("../app_url.zig");
const logging = @import("../features/logging/mod.zig");
const state_mod = @import("state.zig");
const window_manager = @import("window_manager.zig");
const window_profiles = @import("window_profiles.zig");

pub const AppRuntime = struct {
    allocator: std.mem.Allocator,
    state: state_mod.AppState,
    logger: logging.LogService,
    windows: window_manager.WindowManager,
    urls: window_manager.Urls,

    pub fn init(allocator: std.mem.Allocator) !AppRuntime {
        const minibar_url = try app_url.resolveSurface(allocator, .minibar);
        errdefer allocator.free(minibar_url);
        const panel_url = try app_url.resolveSurface(allocator, .control_panel);
        errdefer allocator.free(panel_url);

        var logger = try logging.LogService.init(allocator, .{});
        errdefer logger.deinit();

        var state = state_mod.AppState.init();
        try logger.write(.{
            .level = .INFO,
            .trace_id = state.traceId(),
            .module = "app_runtime",
            .event = "bootstrap_completed",
            .message = "Runtime initialized",
            .metadata_json = "{\"runtime_mode\":\"native_multi_window\"}",
        });

        return .{
            .allocator = allocator,
            .state = state,
            .logger = logger,
            .urls = .{
                .minibar = minibar_url,
                .control_panel = panel_url,
            },
            .windows = window_manager.WindowManager.init(.{
                .minibar = minibar_url,
                .control_panel = panel_url,
            }),
        };
    }

    pub fn deinit(self: *AppRuntime) void {
        self.logger.deinit();
        self.allocator.free(self.urls.minibar);
        self.allocator.free(self.urls.control_panel);
    }

    pub fn run(self: *AppRuntime) !void {
        try self.windows.runMainWindow(&self.logger, self.state.traceId());
    }

    pub fn getBootstrap(self: *AppRuntime, kind: window_profiles.WindowKind) UiBootstrap {
        return .{
            .window_kind = kind,
            .ui_status = self.state.ui_status,
            .trace_id = self.state.traceId(),
            .session_id = self.state.session_id,
            .runtime_mode = self.windows.mode,
            .control_panel_url = self.urls.control_panel,
        };
    }

    pub fn openControlPanel(self: *AppRuntime) !window_manager.RuntimeMode {
        return self.windows.openControlPanel(&self.logger, self.state.traceId());
    }

    pub fn logClientEvent(self: *AppRuntime, payload: ClientLogPayload) !void {
        try self.logger.write(.{
            .level = payload.level,
            .trace_id = payload.trace_id,
            .session_id = payload.session_id,
            .module = payload.module,
            .event = payload.event,
            .message = payload.message,
            .err = payload.@"error",
            .stack = payload.stack,
            .metadata_json = payload.metadata_json,
        });
    }
};

pub const UiBootstrap = struct {
    window_kind: window_profiles.WindowKind,
    ui_status: state_mod.UiStatus,
    trace_id: []const u8,
    session_id: ?[]const u8,
    runtime_mode: window_manager.RuntimeMode,
    control_panel_url: []const u8,
};

pub const ClientLogPayload = struct {
    level: logging.LogLevel,
    trace_id: []const u8,
    session_id: ?[]const u8 = null,
    module: []const u8,
    event: []const u8,
    message: []const u8,
    @"error": ?[]const u8 = null,
    stack: ?[]const u8 = null,
    metadata_json: ?[]const u8 = null,
};

var active_runtime: ?*AppRuntime = null;

pub fn register(runtime: *AppRuntime) void {
    active_runtime = runtime;
}

pub fn unregister() void {
    active_runtime = null;
}

pub fn get() !*AppRuntime {
    return active_runtime orelse error.RuntimeNotInitialized;
}
