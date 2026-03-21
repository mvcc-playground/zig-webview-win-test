const std = @import("std");
extern "kernel32" fn GetProcessId(handle: std.process.Child.Id) callconv(.winapi) u32;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next();
    const frontend_dir = args.next() orelse return error.MissingFrontendDir;
    const frontend_url = args.next() orelse return error.MissingFrontendUrl;
    const app_exe = args.next() orelse return error.MissingAppExe;

    try ensureFrontendDeps(allocator, frontend_dir);
    try terminateExistingListener(allocator, frontend_url);

    var vite = std.process.Child.init(&.{ "bun", "run", "dev" }, allocator);
    vite.cwd = frontend_dir;
    vite.stdin_behavior = .Inherit;
    vite.stdout_behavior = .Inherit;
    vite.stderr_behavior = .Inherit;
    try vite.spawn();
    defer terminateChild(allocator, &vite) catch {};

    try waitForServer(allocator, frontend_url, 20_000, &vite);

    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();
    try env_map.put("FRONTEND_URL", frontend_url);

    var app = std.process.Child.init(&.{app_exe}, allocator);
    app.env_map = &env_map;
    app.stdin_behavior = .Inherit;
    app.stdout_behavior = .Inherit;
    app.stderr_behavior = .Inherit;
    try app.spawn();

    const app_term = try app.wait();
    try terminateChild(allocator, &vite);

    switch (app_term) {
        .Exited => |code| if (code != 0) std.process.exit(code),
        else => std.process.exit(1),
    }
}

fn ensureFrontendDeps(allocator: std.mem.Allocator, frontend_dir: []const u8) !void {
    const vite_path = try std.fs.path.join(allocator, &.{ frontend_dir, "node_modules", "vite" });
    defer allocator.free(vite_path);
    std.fs.cwd().access(vite_path, .{}) catch {
        var child = std.process.Child.init(&.{ "bun", "install" }, allocator);
        child.cwd = frontend_dir;
        child.stdin_behavior = .Inherit;
        child.stdout_behavior = .Inherit;
        child.stderr_behavior = .Inherit;
        try child.spawn();
        const term = try child.wait();
        switch (term) {
            .Exited => |code| if (code != 0) return error.BunInstallFailed,
            else => return error.BunInstallFailed,
        }
    };
}

fn waitForServer(allocator: std.mem.Allocator, url: []const u8, timeout_ms: u64, vite: *std.process.Child) !void {
    const uri = try std.Uri.parse(url);
    const host = uri.host.?.percent_encoded;
    const port: u16 = if (uri.port) |p| @intCast(p) else if (std.mem.eql(u8, uri.scheme, "https")) 443 else 80;
    const deadline = std.time.milliTimestamp() + @as(i64, @intCast(timeout_ms));

    while (std.time.milliTimestamp() < deadline) {
        _ = vite;
        if (try canReach(allocator, host, port)) return;
        std.Thread.sleep(250 * std.time.ns_per_ms);
    }
    return error.ViteTimeout;
}

fn canReach(allocator: std.mem.Allocator, host: []const u8, port: u16) !bool {
    const stream = std.net.tcpConnectToHost(allocator, host, port) catch return false;
    stream.close();
    return true;
}

fn terminateExistingListener(allocator: std.mem.Allocator, url: []const u8) !void {
    const uri = try std.Uri.parse(url);
    const port: u16 = if (uri.port) |p| @intCast(p) else if (std.mem.eql(u8, uri.scheme, "https")) 443 else 80;

    if (@import("builtin").os.tag == .windows) {
        const command = try std.fmt.allocPrint(
            allocator,
            "(Get-NetTCPConnection -LocalPort {d} -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique)",
            .{port},
        );
        defer allocator.free(command);

        var child = std.process.Child.init(&.{ "powershell", "-NoProfile", "-Command", command }, allocator);
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Ignore;
        try child.spawn();
        const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024);
        defer allocator.free(stdout);
        _ = try child.wait();

        const trimmed = std.mem.trim(u8, stdout, " \r\n\t");
        if (trimmed.len == 0) return;
        const pid = std.fmt.parseInt(u32, trimmed, 10) catch return;

        var killer = std.process.Child.init(&.{ "taskkill", "/PID", try std.fmt.allocPrint(allocator, "{d}", .{pid}), "/T", "/F" }, allocator);
        defer allocator.free(killer.argv[2]);
        killer.stdin_behavior = .Ignore;
        killer.stdout_behavior = .Inherit;
        killer.stderr_behavior = .Inherit;
        try killer.spawn();
        _ = try killer.wait();
        return;
    }
}

fn terminateChild(allocator: std.mem.Allocator, child: *std.process.Child) !void {
    if (@import("builtin").os.tag == .windows) {
        const pid = GetProcessId(child.id);
        var killer = std.process.Child.init(&.{ "taskkill", "/PID", try std.fmt.allocPrint(allocator, "{d}", .{pid}), "/T", "/F" }, allocator);
        defer allocator.free(killer.argv[2]);
        killer.stdin_behavior = .Ignore;
        killer.stdout_behavior = .Ignore;
        killer.stderr_behavior = .Ignore;
        try killer.spawn();
        _ = try killer.wait();
        return;
    }

    _ = child.kill() catch {};
    _ = child.wait() catch {};
}
