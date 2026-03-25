const std = @import("std");

pub const app_url = @import("app_url.zig");
pub const app = @import("app/mod.zig");
pub const features = @import("features/mod.zig");
pub const commands = @import("commands/mod.zig");
pub const webview = @import("webview/mod.zig");

pub export fn mini_webview_handle_invoke(req_json: [*:0]const u8, out_json: [*]u8, out_len: usize) callconv(.c) c_int {
    return webview.invoke.handleInvoke(req_json, out_json, out_len);
}

test "root exports command registry" {
    try std.testing.expect(commands.specs.len > 0);
}
