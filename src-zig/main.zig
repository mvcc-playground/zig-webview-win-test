const std = @import("std");
const zig_teste = @import("zig_teste");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa_state.deinit();
    }
    const allocator = gpa_state.allocator();

    const url = zig_teste.app_url.resolve(allocator) catch |err| {
        if (err == error.FrontendEntryNotFound) {
            std.log.err("frontend entry not found. Run `mise build-frontend` or set FRONTEND_URL for dev.", .{});
        }
        return err;
    };
    defer allocator.free(url);

    var webview = try zig_teste.webview.Webview.create(false, null);
    defer webview.destroy();

    try webview.setTitle("zig mini-tauri");
    try webview.setSize(980, 680, .none);
    try webview.navigate(url);
    try webview.run();
}

export fn mini_webview_handle_invoke(req_json: [*:0]const u8, out_json: [*]u8, out_len: usize) callconv(.c) c_int {
    return zig_teste.webview.invoke.handleInvoke(req_json, out_json, out_len);
}
