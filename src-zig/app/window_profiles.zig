const webview = @import("../webview/mod.zig");

pub const WindowKind = enum {
    minibar,
    control_panel,
};

pub const WindowProfile = struct {
    title: []const u8,
    width: c_int,
    height: c_int,
    hint: webview.runtime.SizeHint,
};

pub fn profileFor(kind: WindowKind) WindowProfile {
    return switch (kind) {
        .minibar => .{
            .title = "MiniBar",
            .width = 420,
            .height = 96,
            .hint = .fixed,
        },
        .control_panel => .{
            .title = "Control Panel",
            .width = 980,
            .height = 680,
            .hint = .none,
        },
    };
}

test "window profiles are deterministic" {
    const mini = profileFor(.minibar);
    const panel = profileFor(.control_panel);
    try @import("std").testing.expect(mini.width < panel.width);
    try @import("std").testing.expect(mini.height < panel.height);
}
