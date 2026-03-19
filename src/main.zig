const std = @import("std");
const win32 = @import("win32");
const foundation = win32.foundation;
const windows_and_messaging = win32.ui.windows_and_messaging;

pub fn main() !void {
    var point: foundation.POINT = undefined;
    if (windows_and_messaging.GetCursorPos(&point) == 0) {
        std.debug.print("Failed to get mouse position.\n", .{});
        return error.GetCursorPosFailed;
    }

    std.debug.print("Mouse position: x={}, y={}\n", .{ point.x, point.y });
}
