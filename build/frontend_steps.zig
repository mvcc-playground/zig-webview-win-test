const std = @import("std");

pub const Frontend = struct {
    install: *std.Build.Step.Run,
    check: *std.Build.Step.Run,
    build_cmd: *std.Build.Step.Run,
    build_step: *std.Build.Step,
    dev_step: *std.Build.Step,
};

pub fn add(
    b: *std.Build,
    gen_types_step: *std.Build.Step,
    install_step: *std.Build.Step,
) Frontend {
    const install = b.addSystemCommand(&.{ "bun", "install" });
    install.setCwd(b.path("."));

    const check = b.addSystemCommand(&.{ "bun", "run", "check" });
    check.setCwd(b.path("."));
    check.step.dependOn(&install.step);
    check.step.dependOn(gen_types_step);

    const build_cmd = b.addSystemCommand(&.{ "bun", "run", "build" });
    build_cmd.setCwd(b.path("."));
    build_cmd.step.dependOn(&install.step);
    build_cmd.step.dependOn(gen_types_step);

    const build_step = b.step("frontend", "Install deps and build the Vite frontend");
    build_step.dependOn(&build_cmd.step);

    const dev_step = b.step("dev", "Start Vite dev server and run the Zig app");
    dev_step.dependOn(gen_types_step);
    dev_step.dependOn(&install.step);
    dev_step.dependOn(install_step);
    dev_step.dependOn(addDevOrchestrator(b));

    return .{
        .install = install,
        .check = check,
        .build_cmd = build_cmd,
        .build_step = build_step,
        .dev_step = dev_step,
    };
}

fn addDevOrchestrator(b: *std.Build) *std.Build.Step {
    if (builtinOsIsWindows()) {
        const ps =
            "$ErrorActionPreference='Stop'; " ++
            "$root=(Resolve-Path '.').Path; " ++
            "$app=Join-Path $root 'zig-out\\bin\\zig_teste.exe'; " ++
            "$url='http://127.0.0.1:5173'; " ++
            "$port=5173; " ++
            "$existing=(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique); " ++
            "if ($existing) { taskkill /PID $existing /T /F | Out-Null }; " ++
            "$vite=Start-Process bun -ArgumentList 'run','dev' -WorkingDirectory $root -PassThru; " ++
            "try { " ++
            "  $ready=$false; " ++
            "  for ($i=0; $i -lt 80; $i++) { " ++
            "    try { $res=Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 1; if ($res.StatusCode -lt 500) { $ready=$true; break } } catch {}; " ++
            "    Start-Sleep -Milliseconds 250; " ++
            "  }; " ++
            "  if (-not $ready) { throw 'Vite dev server did not start in time' }; " ++
            "  $env:FRONTEND_URL=$url; " ++
            "  & $app; " ++
            "  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } " ++
            "} finally { " ++
            "  if ($vite -and -not $vite.HasExited) { taskkill /PID $vite.Id /T /F | Out-Null } " ++
            "}";

        const dev = b.addSystemCommand(&.{
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            ps,
        });
        dev.setCwd(b.path("."));
        return &dev.step;
    }

    const fail = b.addFail("`zig build dev` currently has inline orchestration only for Windows. Use `bun run dev` plus `zig build run -Dfrontend-url=http://127.0.0.1:5173` on other platforms.");
    return &fail.step;
}

fn builtinOsIsWindows() bool {
    return @import("builtin").os.tag == .windows;
}
