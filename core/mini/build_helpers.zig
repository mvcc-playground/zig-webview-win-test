const std = @import("std");

pub const AppConfig = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    commands_root_source: std.Build.LazyPath,
    frontend_url: ?[]const u8,
    frontend_dist: []const u8,
    generated_commands_path: []const u8,
    generated_global_path: []const u8,
    generated_invoke_path: []const u8,
    generated_client_path: []const u8,
    app_title: []const u8,
    invoke_binding: []const u8 = "__mini_invoke__",
};

pub const AppArtifacts = struct {
    exe: *std.Build.Step.Compile,
    run_cmd: *std.Build.Step.Run,
    gen_types_cmd: *std.Build.Step.Run,
    commands_module: *std.Build.Module,
};

pub fn addApp(config: AppConfig) AppArtifacts {
    const b = config.b;

    const mini_module = b.addModule("mini", .{
        .root_source_file = b.path("core/mini/src/root.zig"),
        .target = config.target,
        .optimize = config.optimize,
    });

    const commands_module = b.createModule(.{
        .root_source_file = config.commands_root_source,
        .target = config.target,
        .optimize = config.optimize,
        .imports = &.{
            .{ .name = "mini", .module = mini_module },
        },
    });

    const app_options = b.addOptions();
    app_options.addOption(?[]const u8, "frontend_url", config.frontend_url);
    app_options.addOption([]const u8, "frontend_dist", config.frontend_dist);
    app_options.addOption([]const u8, "generated_commands_path", config.generated_commands_path);
    app_options.addOption([]const u8, "generated_global_path", config.generated_global_path);
    app_options.addOption([]const u8, "generated_invoke_path", config.generated_invoke_path);
    app_options.addOption([]const u8, "generated_client_path", config.generated_client_path);
    app_options.addOption([]const u8, "app_title", config.app_title);
    app_options.addOption([]const u8, "invoke_binding", config.invoke_binding);

    const exe_root_module = b.createModule(.{
        .root_source_file = b.path("core/mini/src/app_main.zig"),
        .target = config.target,
        .optimize = config.optimize,
        .imports = &.{
            .{ .name = "mini", .module = mini_module },
            .{ .name = "mini_app_commands", .module = commands_module },
        },
    });
    exe_root_module.addOptions("build_options", app_options);

    const exe = b.addExecutable(.{
        .name = config.name,
        .root_module = exe_root_module,
    });
    linkMiniWebview(exe, b, config.target);
    b.installArtifact(exe);

    const gen_types_exe = b.addExecutable(.{
        .name = b.fmt("{s}_gen_ts_types", .{config.name}),
        .root_module = b.createModule(.{
            .root_source_file = b.path("core/mini/src/tools/gen_ts_types.zig"),
            .target = config.target,
            .optimize = config.optimize,
            .imports = &.{
                .{ .name = "mini", .module = mini_module },
                .{ .name = "mini_app_commands", .module = commands_module },
            },
        }),
    });
    gen_types_exe.root_module.addOptions("build_options", app_options);

    const gen_types_cmd = b.addRunArtifact(gen_types_exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    return .{
        .exe = exe,
        .run_cmd = run_cmd,
        .gen_types_cmd = gen_types_cmd,
        .commands_module = commands_module,
    };
}

pub fn addBinSteps(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    bin_dir_path: []const u8,
) struct { selected_requested: bool, selected_step: ?*std.Build.Step, selected_missing_step: ?*std.Build.Step } {
    const selected_bin = b.option([]const u8, "bin", "Run example/src-zig/bin/<name>.zig with `zig build run -Dbin=<name>`");

    var selected_step: ?*std.Build.Step = null;
    var missing_step: ?*std.Build.Step = null;

    var bin_dir = std.fs.cwd().openDir(bin_dir_path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => null,
        else => @panic("failed to open bin directory"),
    };

    if (bin_dir) |*dir| {
        defer dir.close();
        var it = dir.iterate();
        while (it.next() catch @panic("failed to iterate bin directory")) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;

            const stem = std.fs.path.stem(entry.name);
            const rel_path = b.fmt("{s}/{s}", .{ bin_dir_path, entry.name });

            const bin_exe = b.addExecutable(.{
                .name = stem,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(rel_path),
                    .target = target,
                    .optimize = optimize,
                }),
            });

            b.installArtifact(bin_exe);

            const run_step = b.step(
                b.fmt("run-{s}", .{stem}),
                b.fmt("Run {s}/{s}", .{ bin_dir_path, entry.name }),
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

    const run_bin_step = b.step("run-bin", "Run example/src-zig/bin/<name>.zig (use -Dbin=<name>)");
    if (selected_bin) |selected_name| {
        if (selected_step) |step| {
            run_bin_step.dependOn(step);
        } else {
            const fail = b.addFail(b.fmt("No bin named '{s}' in {s}", .{ selected_name, bin_dir_path }));
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

fn linkMiniWebview(exe: *std.Build.Step.Compile, b: *std.Build, target: std.Build.ResolvedTarget) void {
    exe.addIncludePath(b.path("deps/webview/core/include"));
    exe.addIncludePath(b.path("deps/mswebview2/include"));
    exe.addIncludePath(b.path("deps/webview/compatibility/mingw/include"));
    exe.addCSourceFile(.{
        .file = b.path("core/mini/native/webview_bridge.cc"),
        .flags = &.{ "-std=c++14", "-DWEBVIEW_STATIC" },
    });
    exe.linkLibCpp();

    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("advapi32");
            exe.linkSystemLibrary("ole32");
            exe.linkSystemLibrary("shell32");
            exe.linkSystemLibrary("shlwapi");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("version");
        },
        .macos => {
            exe.linkFramework("Cocoa");
            exe.linkFramework("WebKit");
            exe.linkFramework("Foundation");
            exe.linkSystemLibrary("dl");
        },
        .linux => {
            exe.linkSystemLibrary("gtk-3");
            exe.linkSystemLibrary("webkit2gtk-4.1");
            exe.linkSystemLibrary("dl");
        },
        else => {},
    }
}
