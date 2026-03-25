const app = @import("../app/mod.zig");
const logging = @import("../features/logging/mod.zig");

pub const GetUiBootstrapInput = struct {
    window_kind: app.window_profiles.WindowKind,
};

pub const GetUiBootstrapOutput = struct {
    window_kind: app.window_profiles.WindowKind,
    ui_status: app.state.UiStatus,
    trace_id: []const u8,
    session_id: ?[]const u8,
    runtime_mode: app.window_manager.RuntimeMode,
    control_panel_url: []const u8,
};

pub const LogClientEventInput = struct {
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

pub const LogClientEventOutput = struct {
    accepted: bool,
};

pub const OpenControlPanelOutput = struct {
    opened: bool,
    runtime_mode: app.window_manager.RuntimeMode,
};

pub fn get_ui_bootstrap(input: GetUiBootstrapInput) !GetUiBootstrapOutput {
    const runtime = try app.runtime.get();
    const boot = runtime.getBootstrap(input.window_kind);
    return .{
        .window_kind = boot.window_kind,
        .ui_status = boot.ui_status,
        .trace_id = boot.trace_id,
        .session_id = boot.session_id,
        .runtime_mode = boot.runtime_mode,
        .control_panel_url = boot.control_panel_url,
    };
}

pub fn log_client_event(input: LogClientEventInput) !LogClientEventOutput {
    const runtime = try app.runtime.get();
    try runtime.logClientEvent(.{
        .level = input.level,
        .trace_id = input.trace_id,
        .session_id = input.session_id,
        .module = input.module,
        .event = input.event,
        .message = input.message,
        .@"error" = input.@"error",
        .stack = input.stack,
        .metadata_json = input.metadata_json,
    });
    return .{ .accepted = true };
}

pub fn open_control_panel() !OpenControlPanelOutput {
    const runtime = try app.runtime.get();
    const mode = try runtime.openControlPanel();
    return .{
        .opened = true,
        .runtime_mode = mode,
    };
}

pub const commands = .{
    .get_ui_bootstrap = get_ui_bootstrap,
    .log_client_event = log_client_event,
    .open_control_panel = open_control_panel,
};

pub const command_meta = .{
    .get_ui_bootstrap = .{
        .arg_names = .{ .@"0" = "input" },
    },
    .log_client_event = .{
        .arg_names = .{ .@"0" = "input" },
    },
};
