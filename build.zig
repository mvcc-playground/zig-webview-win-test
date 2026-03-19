const std = @import("std");
const bin_steps = @import("build/bin_steps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const zigwin32 = b.dependency("zigwin32", .{});
    const win32_module = zigwin32.module("win32");

    const app_module = b.addModule("zig_teste", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "zig_teste",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_teste", .module = app_module },
                .{ .name = "win32", .module = win32_module },
            },
        }),
    });
    linkMiniWebview(exe, b, target);
    b.installArtifact(exe);

    const commands_module = b.createModule(.{
        .root_source_file = b.path("src/commands/mod.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gen_types_exe = b.addExecutable(.{
        .name = "gen_ts_types",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tools/gen_ts_types.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zig_teste", .module = app_module },
                .{ .name = "commands", .module = commands_module },
            },
        }),
    });
    const gen_types_cmd = b.addRunArtifact(gen_types_exe);
    const gen_types_step = b.step("gen-types", "Generate TypeScript type definitions for invoke");
    gen_types_step.dependOn(&gen_types_cmd.step);

    const bins = bin_steps.add(.{
        .b = b,
        .target = target,
        .optimize = optimize,
        .app_module = app_module,
        .win32_module = win32_module,
    });

    const run_step = b.step("run", "Run app, or use -Dbin=<name> to run src/bin/<name>.zig");
    run_step.dependOn(&gen_types_cmd.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    if (bins.selected_requested) {
        if (bins.selected_step) |selected| {
            run_step.dependOn(selected);
        } else if (bins.selected_missing_step) |missing| {
            run_step.dependOn(missing);
        }
    } else {
        run_step.dependOn(&run_cmd.step);
    }

    const mod_tests = b.addTest(.{ .root_module = app_module });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}

fn linkMiniWebview(exe: *std.Build.Step.Compile, b: *std.Build, target: std.Build.ResolvedTarget) void {
    exe.addIncludePath(b.path("deps/webview/core/include"));
    exe.addIncludePath(b.path("deps/mswebview2/include"));
    exe.addIncludePath(b.path("deps/webview/compatibility/mingw/include"));
    exe.addCSourceFile(.{
        .file = b.path("src/native/webview_bridge.cc"),
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
