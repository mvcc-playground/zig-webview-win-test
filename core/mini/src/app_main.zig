const mini = @import("root.zig");
const app_commands = @import("mini_app_commands");

pub fn main() !void {
    try mini.runtime.run(app_commands);
}

export fn mini_handle_invoke(req_json: [*:0]const u8, out_json: [*]u8, out_len: usize) callconv(.c) c_int {
    return mini.runtime.handleInvoke(app_commands, req_json, out_json, out_len);
}
