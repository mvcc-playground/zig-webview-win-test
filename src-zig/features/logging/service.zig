const std = @import("std");

pub const LogLevel = enum {
    DEBUG,
    INFO,
    WARN,
    ERROR,
};

pub const LogEvent = struct {
    level: LogLevel,
    trace_id: []const u8,
    session_id: ?[]const u8 = null,
    module: []const u8,
    event: []const u8,
    message: []const u8,
    err: ?[]const u8 = null,
    stack: ?[]const u8 = null,
    metadata_json: ?[]const u8 = null,
};

pub const Config = struct {
    max_file_bytes: u64 = 512 * 1024,
    max_files: usize = 5,
};

pub const LogService = struct {
    allocator: std.mem.Allocator,
    dir_path: []const u8,
    file_path: []const u8,
    config: Config,
    lock: std.Thread.Mutex = .{},
    file: ?std.fs.File = null,

    pub fn init(allocator: std.mem.Allocator, config: Config) !LogService {
        const dir_path = try resolveLogDir(allocator);
        defer allocator.free(dir_path);
        return initAtDir(allocator, dir_path, config);
    }

    pub fn initAtDir(allocator: std.mem.Allocator, dir_path: []const u8, config: Config) !LogService {
        const owned_dir = try allocator.dupe(u8, dir_path);
        errdefer allocator.free(owned_dir);
        try std.fs.cwd().makePath(owned_dir);

        const file_path = try std.fs.path.join(allocator, &.{ owned_dir, "app.log" });
        errdefer allocator.free(file_path);

        var out: LogService = .{
            .allocator = allocator,
            .dir_path = owned_dir,
            .file_path = file_path,
            .config = config,
        };
        try out.openForAppend();
        return out;
    }

    pub fn deinit(self: *LogService) void {
        self.lock.lock();
        defer self.lock.unlock();
        if (self.file) |*f| {
            f.close();
            self.file = null;
        }
        self.allocator.free(self.file_path);
        self.allocator.free(self.dir_path);
    }

    pub fn write(self: *LogService, event: LogEvent) !void {
        self.lock.lock();
        defer self.lock.unlock();

        const line = try self.serialize(event);
        defer self.allocator.free(line);

        try self.rotateIfNeeded(@as(u64, @intCast(line.len + 1)));
        const f = self.file orelse return error.LogFileUnavailable;
        try f.writeAll(line);
        try f.writeAll("\n");
        try f.sync();
    }

    fn serialize(self: *LogService, event: LogEvent) ![]u8 {
        const payload = .{
            .timestamp = std.time.milliTimestamp(),
            .level = @tagName(event.level),
            .trace_id = event.trace_id,
            .session_id = event.session_id,
            .module = event.module,
            .event = event.event,
            .message = event.message,
            .@"error" = event.err,
            .stack = event.stack,
            .metadata_json = event.metadata_json,
        };
        return std.fmt.allocPrint(self.allocator, "{f}", .{std.json.fmt(payload, .{})});
    }

    fn rotateIfNeeded(self: *LogService, incoming: u64) !void {
        const f = self.file orelse return error.LogFileUnavailable;
        const stat = try f.stat();
        if (stat.size + incoming <= self.config.max_file_bytes) return;

        f.close();
        self.file = null;
        try self.rotateFiles();
        try self.openForAppend();
    }

    fn rotateFiles(self: *LogService) !void {
        if (self.config.max_files <= 1) {
            const rotated = try std.fs.path.join(self.allocator, &.{ self.dir_path, "app.log.1" });
            defer self.allocator.free(rotated);
            std.fs.cwd().rename(self.file_path, rotated) catch {};
            return;
        }

        var i: usize = self.config.max_files - 1;
        while (true) {
            const from_name = try std.fmt.allocPrint(self.allocator, "app.log.{d}", .{i});
            defer self.allocator.free(from_name);
            const to_name = try std.fmt.allocPrint(self.allocator, "app.log.{d}", .{i + 1});
            defer self.allocator.free(to_name);
            const from = try std.fs.path.join(self.allocator, &.{ self.dir_path, from_name });
            defer self.allocator.free(from);
            const to = try std.fs.path.join(self.allocator, &.{ self.dir_path, to_name });
            defer self.allocator.free(to);
            std.fs.cwd().rename(from, to) catch {};
            if (i == 1) break;
            i -= 1;
        }

        const rotated = try std.fs.path.join(self.allocator, &.{ self.dir_path, "app.log.1" });
        defer self.allocator.free(rotated);
        std.fs.cwd().rename(self.file_path, rotated) catch {};
    }

    fn openForAppend(self: *LogService) !void {
        self.file = try std.fs.cwd().createFile(self.file_path, .{ .truncate = false, .read = true });
        try self.file.?.seekFromEnd(0);
    }
};

fn resolveLogDir(allocator: std.mem.Allocator) ![]u8 {
    const appdata = std.process.getEnvVarOwned(allocator, "APPDATA") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return std.fs.path.join(allocator, &.{ ".", "logs" }),
        else => return err,
    };
    defer allocator.free(appdata);
    return std.fs.path.join(allocator, &.{ appdata, "zig-teste", "logs" });
}

test "writes JSONL with required core fields" {
    var dir_buf: [256]u8 = undefined;
    const test_dir = try std.fmt.bufPrint(&dir_buf, ".zig-cache/test-logs-{d}", .{std.time.microTimestamp()});
    try std.fs.cwd().makePath(test_dir);

    var logger = try LogService.initAtDir(std.testing.allocator, test_dir, .{ .max_file_bytes = 1024, .max_files = 2 });
    defer logger.deinit();

    try logger.write(.{
        .level = .INFO,
        .trace_id = "trace-1",
        .module = "logging_test",
        .event = "write_jsonl",
        .message = "ok",
    });

    const bytes = try std.fs.cwd().readFileAlloc(std.testing.allocator, logger.file_path, 4096);
    defer std.testing.allocator.free(bytes);
    const trimmed = std.mem.trim(u8, bytes, "\r\n\t ");
    const parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, trimmed, .{});
    defer parsed.deinit();
    try std.testing.expectEqualStrings("INFO", parsed.value.object.get("level").?.string);
    try std.testing.expectEqualStrings("trace-1", parsed.value.object.get("trace_id").?.string);
}

test "rotates when max size is exceeded" {
    var dir_buf: [256]u8 = undefined;
    const test_dir = try std.fmt.bufPrint(&dir_buf, ".zig-cache/test-logs-rotate-{d}", .{std.time.microTimestamp()});
    try std.fs.cwd().makePath(test_dir);

    var logger = try LogService.initAtDir(std.testing.allocator, test_dir, .{ .max_file_bytes = 150, .max_files = 2 });
    defer logger.deinit();

    var n: usize = 0;
    while (n < 12) : (n += 1) {
        try logger.write(.{
            .level = .INFO,
            .trace_id = "trace-rotate",
            .module = "logging_test",
            .event = "line",
            .message = "this is a line large enough to trigger file rotation quickly",
        });
    }

    const rotated = try std.fs.path.join(std.testing.allocator, &.{ logger.dir_path, "app.log.1" });
    defer std.testing.allocator.free(rotated);
    std.fs.cwd().access(rotated, .{}) catch return error.TestExpectedEqual;
}
