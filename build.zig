const std = @import("std");
const mini = @import("core/mini/build_helpers.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const frontend_url = b.option([]const u8, "frontend-url", "Frontend dev URL override");
    const frontend_dist = b.option([]const u8, "frontend-dist", "Frontend dist index.html path override") orelse "example/app/dist/index.html";
    const frontend_dir = b.path("example/app");

    const app = mini.addApp(.{
        .b = b,
        .target = target,
        .optimize = optimize,
        .name = "mini_example",
        .commands_root_source = b.path("example/src-zig/commands/mod.zig"),
        .frontend_url = frontend_url,
        .frontend_dist = frontend_dist,
        .generated_commands_path = "example/app/src/types-generated/commands.generated.d.ts",
        .generated_global_path = "example/app/src/types-generated/global.generated.d.ts",
        .generated_invoke_path = "example/app/src/lib/invoke.ts",
        .generated_client_path = "example/app/src/lib/commands.ts",
        .app_title = "zig mini toolkit example",
    });

    const gen_types_step = b.step("gen-types", "Generate TypeScript type definitions for the example app");
    gen_types_step.dependOn(&app.gen_types_cmd.step);

    const ensure_frontend_deps = b.addSystemCommand(&.{ "bun", "install" });
    ensure_frontend_deps.setCwd(frontend_dir);

    const frontend_build = b.addSystemCommand(&.{ "bun", "run", "build" });
    frontend_build.setCwd(frontend_dir);
    frontend_build.step.dependOn(&ensure_frontend_deps.step);
    frontend_build.step.dependOn(&app.gen_types_cmd.step);

    const build_frontend_step = b.step("build-frontend", "Build the example frontend");
    build_frontend_step.dependOn(&frontend_build.step);

    const bins = mini.addBinSteps(b, target, optimize, "example/src-zig/bin");

    const run_step = b.step("run", "Run the example app, or use -Dbin=<name> to run example/src-zig/bin/<name>.zig");
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
            .root_source_file = b.path("core/mini/src/tools/dev_runner.zig"),
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

    const dev_step = b.step("dev", "Run the example app against the local Vite dev server");
    dev_step.dependOn(&run_dev.step);

    const core_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("core/mini/src/command_runtime.zig"),
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
