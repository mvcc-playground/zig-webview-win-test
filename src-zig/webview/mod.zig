const invoke_runtime = @import("invoke.zig");
pub const runtime = @import("runtime.zig");

comptime {
    _ = invoke_runtime;
}

pub const Webview = runtime.Webview;
pub const invoke = invoke_runtime;
