const std = @import("std");
const desktop_example = @import("example/desktop-example/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    desktop_example.addProjectSteps(b, target, optimize, .{
        .core_dir = "core/mini",
        .deps_dir = "deps",
        .project_dir = "example/desktop-example",
    });
}
