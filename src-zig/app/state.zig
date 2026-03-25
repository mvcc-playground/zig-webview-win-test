const std = @import("std");

pub const UiStatus = enum {
    ready,
    recording,
    processing,
    inserted,
    @"error",
};

pub const AppState = struct {
    ui_status: UiStatus = .ready,
    trace_id: [36]u8 = undefined,
    session_id: ?[]const u8 = null,

    pub fn init() AppState {
        var out: AppState = .{};
        out.regenerateTraceId();
        return out;
    }

    pub fn regenerateTraceId(self: *AppState) void {
        var bytes: [16]u8 = undefined;
        std.crypto.random.bytes(&bytes);
        _ = std.fmt.bufPrint(
            &self.trace_id,
            "{x:0>2}{x:0>2}{x:0>2}{x:0>2}-{x:0>2}{x:0>2}-{x:0>2}{x:0>2}-{x:0>2}{x:0>2}-{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}{x:0>2}",
            .{
                bytes[0],  bytes[1],  bytes[2],  bytes[3],
                bytes[4],  bytes[5],  bytes[6],  bytes[7],
                bytes[8],  bytes[9],  bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15],
            },
        ) catch unreachable;
    }

    pub fn traceId(self: *const AppState) []const u8 {
        return self.trace_id[0..];
    }
};

test "trace id is UUID-like and stable length" {
    var state = AppState.init();
    try std.testing.expectEqual(@as(usize, 36), state.traceId().len);
    try std.testing.expect(state.traceId()[8] == '-');
    try std.testing.expect(state.traceId()[13] == '-');
    try std.testing.expect(state.traceId()[18] == '-');
    try std.testing.expect(state.traceId()[23] == '-');
}
