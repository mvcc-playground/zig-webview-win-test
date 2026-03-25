const std = @import("std");

pub fn hasSources() bool {
    std.fs.cwd().access("deps/webview/core/include/webview/webview.h", .{}) catch return false;
    return true;
}

pub fn linkApp(exe: *std.Build.Step.Compile, b: *std.Build, target: std.Build.ResolvedTarget) void {
    ensureSources();

    exe.addIncludePath(b.path("deps/webview/core/include"));
    exe.addIncludePath(b.path("deps/mswebview2/include"));
    exe.addIncludePath(b.path("deps/webview/compatibility/mingw/include"));
    exe.addCSourceFile(.{
        .file = b.path("src-zig/native/webview_bridge.cc"),
        .flags = &.{ "-std=c++14", "-DWEBVIEW_STATIC" },
    });
    exe.linkLibCpp();

    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("advapi32");
            exe.linkSystemLibrary("gdi32");
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

fn ensureSources() void {
    if (hasSources()) return;
    @panic("Missing deps/webview sources. Run `git submodule update --init --recursive` before building native app targets.");
}
