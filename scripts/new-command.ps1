param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name
)

$slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
$slug = $slug.Trim('-')
if ([string]::IsNullOrWhiteSpace($slug)) {
    throw "Invalid command name. Use letters and numbers."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$commandsDir = Join-Path $projectRoot "src/commands"
$registryPath = Join-Path $commandsDir "registry.zig"
$commandFile = Join-Path $commandsDir "$slug.zig"

if (-not (Test-Path $commandsDir)) {
    throw "Commands directory not found: $commandsDir"
}
if (-not (Test-Path $registryPath)) {
    throw "Registry file not found: $registryPath"
}
if (Test-Path $commandFile) {
    throw "Command file already exists: $commandFile"
}

$template = @"
const std = @import("std");

pub const name = "$slug";

pub const Request = struct {
    input: []const u8 = "",
};

pub const Response = struct {
    command: []const u8 = name,
    ok: bool,
    echoed: []const u8,
    timestamp_ms: i64,
};

pub fn handle(req: Request) Response {
    return .{
        .command = name,
        .ok = true,
        .echoed = req.input,
        .timestamp_ms = std.time.milliTimestamp(),
    };
}
"@

Set-Content -Path $commandFile -Value $template -NoNewline

$registry = Get-Content -Path $registryPath -Raw
$startMarker = "// @commands:start"
$endMarker = "// @commands:end"

$startPos = $registry.IndexOf($startMarker)
$endPos = $registry.IndexOf($endMarker)
if ($startPos -lt 0 -or $endPos -lt 0 -or $endPos -le $startPos) {
    throw "Registry markers not found in src/commands/registry.zig"
}

$insertPos = $registry.IndexOf($endMarker)
$importLine = "    @import(`"$slug.zig`"),`r`n"
if ($registry.Contains($importLine)) {
    throw "Command already registered in registry: $slug"
}

$updated = $registry.Insert($insertPos, $importLine)
Set-Content -Path $registryPath -Value $updated -NoNewline

Write-Host "Created command file: $commandFile"
Write-Host "Registered command: $slug"
Write-Host "Next: zig build gen-types"
