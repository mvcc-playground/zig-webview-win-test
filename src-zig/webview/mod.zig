const invoke_runtime = @import("invoke.zig");

comptime {
    _ = invoke_runtime;
}

pub const Webview = @import("runtime.zig").Webview;
pub const invoke = invoke_runtime;
