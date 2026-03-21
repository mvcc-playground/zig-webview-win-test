const std = @import("std");

pub const app_url = @import("app_url.zig");
pub const commands = @import("commands/mod.zig");
pub const webview = @import("webview/mod.zig");

test "root exports command registry" {
    try std.testing.expect(commands.specs.len > 0);
}
