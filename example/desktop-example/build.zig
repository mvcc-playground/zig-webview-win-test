const std = @import("std");

pub const Layout = struct {
    core_dir: []const u8,
    deps_dir: []const u8,
    project_dir: []const u8,
};

const AppConfig = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    commands_root_source: std.Build.LazyPath,
    mini_root_source: std.Build.LazyPath,
    mini_app_main_source: std.Build.LazyPath,
    mini_gen_types_source: std.Build.LazyPath,
    mini_bridge_source: std.Build.LazyPath,
    deps_webview_include: std.Build.LazyPath,
    deps_mswebview2_include: std.Build.LazyPath,
    deps_webview_compat_include: std.Build.LazyPath,
    frontend_url: ?[]const u8,
    frontend_dist: []const u8,
    generated_commands_path: []const u8,
    generated_global_path: []const u8,
    generated_invoke_path: []const u8,
    generated_client_path: []const u8,
    app_title: []const u8,
    invoke_binding: []const u8 = "__mini_invoke__",
};

const AppArtifacts = struct {
    exe: *std.Build.Step.Compile,
    run_cmd: *std.Build.Step.Run,
    gen_types_cmd: *std.Build.Step.Run,
};

fn addApp(config: AppConfig) AppArtifacts {
    const b = config.b;

    const mini_module = b.addModule("mini", .{
        .root_source_file = config.mini_root_source,
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
        .root_source_file = config.mini_app_main_source,
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
    linkMiniWebview(exe, config);
    b.installArtifact(exe);

    const gen_types_exe = b.addExecutable(.{
        .name = b.fmt("{s}_gen_ts_types", .{config.name}),
        .root_module = b.createModule(.{
            .root_source_file = config.mini_gen_types_source,
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
    };
}

fn addBinSteps(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    bin_dir_path: []const u8,
) struct { selected_requested: bool, selected_step: ?*std.Build.Step, selected_missing_step: ?*std.Build.Step } {
    const selected_bin = b.option(
        []const u8,
        "bin",
        b.fmt("Run {s}/<name>.zig with `zig build run -Dbin=<name>`", .{bin_dir_path}),
    );

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

    const run_bin_step = b.step(
        "run-bin",
        b.fmt("Run {s}/<name>.zig (use -Dbin=<name>)", .{bin_dir_path}),
    );
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

fn linkMiniWebview(exe: *std.Build.Step.Compile, config: AppConfig) void {
    exe.addIncludePath(config.deps_webview_include);
    exe.addIncludePath(config.deps_mswebview2_include);
    exe.addIncludePath(config.deps_webview_compat_include);
    exe.addCSourceFile(.{
        .file = config.mini_bridge_source,
        .flags = &.{ "-std=c++14", "-DWEBVIEW_STATIC" },
    });
    exe.linkLibCpp();

    switch (config.target.result.os.tag) {
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

pub fn addProjectSteps(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    layout: Layout,
) void {
    const frontend_url = b.option([]const u8, "frontend-url", "Frontend dev URL override");
    const frontend_dist_default = b.fmt("{s}/dist/index.html", .{layout.project_dir});
    const frontend_dist = b.option([]const u8, "frontend-dist", "Frontend dist index.html path override") orelse frontend_dist_default;
    const frontend_dir = b.path(layout.project_dir);

    const app = addApp(.{
        .b = b,
        .target = target,
        .optimize = optimize,
        .name = "desktop_example",
        .commands_root_source = b.path(b.fmt("{s}/src-zig/commands/mod.zig", .{layout.project_dir})),
        .mini_root_source = b.path(b.fmt("{s}/src/root.zig", .{layout.core_dir})),
        .mini_app_main_source = b.path(b.fmt("{s}/src/app_main.zig", .{layout.core_dir})),
        .mini_gen_types_source = b.path(b.fmt("{s}/src/tools/gen_ts_types.zig", .{layout.core_dir})),
        .mini_bridge_source = b.path(b.fmt("{s}/native/webview_bridge.cc", .{layout.core_dir})),
        .deps_webview_include = b.path(b.fmt("{s}/webview/core/include", .{layout.deps_dir})),
        .deps_mswebview2_include = b.path(b.fmt("{s}/mswebview2/include", .{layout.deps_dir})),
        .deps_webview_compat_include = b.path(b.fmt("{s}/webview/compatibility/mingw/include", .{layout.deps_dir})),
        .frontend_url = frontend_url,
        .frontend_dist = frontend_dist,
        .generated_commands_path = b.fmt("{s}/src/types-generated/commands.generated.d.ts", .{layout.project_dir}),
        .generated_global_path = b.fmt("{s}/src/types-generated/global.generated.d.ts", .{layout.project_dir}),
        .generated_invoke_path = b.fmt("{s}/src/lib/invoke.ts", .{layout.project_dir}),
        .generated_client_path = b.fmt("{s}/src/lib/commands.ts", .{layout.project_dir}),
        .app_title = "zig mini toolkit desktop example",
    });

    const gen_types_step = b.step("gen-types", "Generate TypeScript type definitions for the desktop example");
    gen_types_step.dependOn(&app.gen_types_cmd.step);

    const ensure_frontend_deps = b.addSystemCommand(&.{ "bun", "install" });
    ensure_frontend_deps.setCwd(frontend_dir);

    const frontend_build = b.addSystemCommand(&.{ "bun", "run", "build" });
    frontend_build.setCwd(frontend_dir);
    frontend_build.step.dependOn(&ensure_frontend_deps.step);
    frontend_build.step.dependOn(&app.gen_types_cmd.step);

    const build_frontend_step = b.step("build-frontend", "Build the desktop example frontend");
    build_frontend_step.dependOn(&frontend_build.step);

    const bin_dir_path = b.fmt("{s}/src-zig/bin", .{layout.project_dir});
    const bins = addBinSteps(b, target, optimize, bin_dir_path);

    const run_step = b.step(
        "run",
        b.fmt("Run the desktop example, or use -Dbin=<name> to run {s}/<name>.zig", .{bin_dir_path}),
    );
    if (bins.selected_requested) {
        if (bins.selected_step) |selected| {
            run_step.dependOn(selected);
        } else if (bins.selected_missing_step) |missing| {
            run_step.dependOn(missing);
        }
    } else {
        run_step.dependOn(&frontend_build.step);
        run_step.dependOn(&app.run_cmd.step);
    }

    const dev_runner = b.addExecutable(.{
        .name = "mini_dev_runner",
        .root_module = b.createModule(.{
            .root_source_file = b.path(b.fmt("{s}/src/tools/dev_runner.zig", .{layout.core_dir})),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_dev = b.addRunArtifact(dev_runner);
    run_dev.step.dependOn(&ensure_frontend_deps.step);
    run_dev.step.dependOn(&app.gen_types_cmd.step);
    run_dev.addDirectoryArg(frontend_dir);
    run_dev.addArg(frontend_url orelse "http://127.0.0.1:5173");
    run_dev.addFileArg(app.exe.getEmittedBin());

    const dev_step = b.step("dev", "Run the desktop example against the local Vite dev server");
    dev_step.dependOn(&run_dev.step);

    const core_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path(b.fmt("{s}/src/command_runtime.zig", .{layout.core_dir})),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_core_tests = b.addRunArtifact(core_tests);

    const app_tests = b.addTest(.{ .root_module = app.exe.root_module });
    const run_app_tests = b.addRunArtifact(app_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_core_tests.step);
    test_step.dependOn(&run_app_tests.step);

    b.getInstallStep().dependOn(&frontend_build.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addProjectSteps(b, target, optimize, .{
        .core_dir = "../../core/mini",
        .deps_dir = "../../deps",
        .project_dir = ".",
    });
}
