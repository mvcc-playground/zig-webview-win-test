const std = @import("std");
const zig_teste = @import("zig_teste");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa_state.deinit();
    }
    const allocator = gpa_state.allocator();

    zig_teste.webview.runtime.configureInvokeHandler(zig_teste.mini_webview_handle_invoke);

    var runtime = zig_teste.app.runtime.AppRuntime.init(allocator) catch |err| {
        if (err == error.FrontendEntryNotFound) {
            std.log.err("frontend entry not found. Run `mise build-frontend` or set FRONTEND_URL for dev.", .{});
        }
        return err;
    };
    defer runtime.deinit();

    zig_teste.app.runtime.register(&runtime);
    defer zig_teste.app.runtime.unregister();
    try runtime.run();
}
