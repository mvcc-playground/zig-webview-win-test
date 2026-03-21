const std = @import("std");
const bin_steps = @import("build/bin_steps.zig");
const frontend_steps = @import("build/frontend_steps.zig");
const webview_steps = @import("build/webview_steps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const frontend_url = b.option([]const u8, "frontend-url", "Frontend dev URL override");
    const frontend_dist = b.option([]const u8, "frontend-dist", "Frontend dist index.html path override") orelse "dist/index.html";

    const app_module = b.addModule("zig_teste", .{
        .root_source_file = b.path("src-zig/root.zig"),
        .target = target,
    });

    const app_options = b.addOptions();
    app_options.addOption(?[]const u8, "frontend_url", frontend_url);
    app_options.addOption([]const u8, "frontend_dist", frontend_dist);
    app_module.addOptions("build_options", app_options);

    const exe_root_module = b.createModule(.{
        .root_source_file = b.path("src-zig/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zig_teste", .module = app_module },
        },
    });
    exe_root_module.addOptions("build_options", app_options);

    const exe = b.addExecutable(.{
        .name = "zig_teste",
        .root_module = exe_root_module,
    });
    webview_steps.linkApp(exe, b, target);
    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);

    const commands_module = b.createModule(.{
        .root_source_file = b.path("src-zig/commands/mod.zig"),
        .target = target,
        .optimize = optimize,
    });

    const gen_types_exe = b.addExecutable(.{
        .name = "gen_ts_types",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src-zig/tools/gen_ts_types.zig"),
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
    });

    const run_step = b.step("run", "Run app, or use -Dbin=<name> to run src-zig/bin/<name>.zig");
    run_step.dependOn(&gen_types_cmd.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&install_exe.step);
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

    const frontend = frontend_steps.add(b, &gen_types_cmd.step, &install_exe.step);
    b.getInstallStep().dependOn(&gen_types_cmd.step);
    b.getInstallStep().dependOn(&frontend.build_cmd.step);
    if (frontend_url == null) {
        run_cmd.step.dependOn(&frontend.build_cmd.step);
    }

    const mod_tests = b.addTest(.{ .root_module = app_module });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&frontend.check.step);
    test_step.dependOn(&run_mod_tests.step);
    if (webview_steps.hasSources()) {
        const exe_tests = b.addTest(.{ .root_module = exe.root_module });
        const run_exe_tests = b.addRunArtifact(exe_tests);
        test_step.dependOn(&run_exe_tests.step);
    } else {
        const fail = b.addFail("Missing deps/webview sources. Run `git submodule update --init --recursive` before building native app targets.");
        test_step.dependOn(&fail.step);
    }
}
