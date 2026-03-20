param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name
)

$slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
$slug = $slug.Trim('-')

if ([string]::IsNullOrWhiteSpace($slug)) {
    throw "Invalid name. Use letters and numbers."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$binDir = Join-Path $projectRoot "src-zig/bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$filePath = Join-Path $binDir ("get-{0}.zig" -f $slug)
if (Test-Path $filePath) {
    throw "File already exists: $filePath"
}

$code = @'
const std = @import("std");
const builtin = @import("builtin");

const POINT = extern struct {
    x: i32,
    y: i32,
};

extern "user32" fn GetCursorPos(lp_point: *POINT) callconv(.winapi) i32;

pub fn main() !void {
    if (builtin.os.tag != .windows) {
        std.debug.print("This example works only on Windows.\n", .{});
        return;
    }

    var point: POINT = .{ .x = 0, .y = 0 };
    const ok = GetCursorPos(&point);
    if (ok == 0) return error.GetCursorPosFailed;

    std.debug.print("Mouse position: x={d}, y={d}\n", .{ point.x, point.y });
}
'@

Set-Content -Path $filePath -Value $code -NoNewline
Write-Host "Created $filePath"
