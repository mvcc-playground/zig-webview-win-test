const std = @import("std");

pub const Config = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    app_module: *std.Build.Module,
    win32_module: *std.Build.Module,
};

pub const Result = struct {
    selected_requested: bool,
    selected_step: ?*std.Build.Step,
    selected_missing_step: ?*std.Build.Step,
};

pub fn add(config: Config) Result {
    const b = config.b;
    const selected_bin = b.option([]const u8, "bin", "Run src-zig/bin/<name>.zig with `zig build run -Dbin=<name>`");

    var selected_step: ?*std.Build.Step = null;
    var missing_step: ?*std.Build.Step = null;

    var bin_dir = std.fs.cwd().openDir("src-zig/bin", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => null,
        else => @panic("failed to open src-zig/bin"),
    };

    if (bin_dir) |*dir| {
        defer dir.close();
        var it = dir.iterate();
        while (it.next() catch @panic("failed to iterate src-zig/bin")) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

            const stem = std.fs.path.stem(entry.name);
            const rel_path = b.fmt("src-zig/bin/{s}", .{entry.name});

            const bin_exe = b.addExecutable(.{
                .name = stem,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(rel_path),
                    .target = config.target,
                    .optimize = config.optimize,
                    .imports = &.{
                        .{ .name = "zig_teste", .module = config.app_module },
                        .{ .name = "win32", .module = config.win32_module },
                    },
                }),
            });

            b.installArtifact(bin_exe);

            const run_step = b.step(
                b.fmt("run-{s}", .{stem}),
                b.fmt("Run src-zig/bin/{s}", .{entry.name}),
            );
            const run_cmd = b.addRunArtifact(bin_exe);
            run_step.dependOn(&run_cmd.step);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| run_cmd.addArgs(args);

            if (selected_bin) |selected_name| {
                if (std.mem.eql(u8, selected_name, stem)) {
                    selected_step = &run_cmd.step;
                }
            }
        }
    }

    const run_bin_step = b.step("run-bin", "Run src-zig/bin/<name>.zig (use -Dbin=<name>)");
    if (selected_bin) |selected_name| {
        if (selected_step) |step| {
            run_bin_step.dependOn(step);
        } else {
            const fail = b.addFail(b.fmt("No bin named '{s}' in src-zig/bin", .{selected_name}));
            run_bin_step.dependOn(&fail.step);
            missing_step = &fail.step;
        }
    } else {
        const fail = b.addFail("Missing -Dbin=<name>. Example: zig build run-bin -Dbin=get-mouse-position");
        run_bin_step.dependOn(&fail.step);
    }

    return .{
        .selected_requested = selected_bin != null,
        .selected_step = selected_step,
        .selected_missing_step = missing_step,
    };
}
