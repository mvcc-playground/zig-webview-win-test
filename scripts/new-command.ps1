param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name
)

$slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
$slug = $slug.Trim('_')
if ([string]::IsNullOrWhiteSpace($slug)) {
    throw "Invalid command name. Use letters and numbers."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$commandsDir = Join-Path $projectRoot "src-zig/commands"
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
pub const Input = struct {
    input: []const u8 = "",
};

pub const Output = struct {
    command: []const u8 = "$slug",
    ok: bool,
    echoed: []const u8,
};

pub fn $slug(input: Input) Output {
    return .{
        .command = "$slug",
        .ok = true,
        .echoed = input.input,
    };
}

pub const commands = .{
    .$slug = $slug,
};
"@

Set-Content -Path $commandFile -Value $template -NoNewline

$registry = Get-Content -Path $registryPath -Raw
$startMarker = "// @modules:start"
$endMarker = "// @modules:end"

$startPos = $registry.IndexOf($startMarker)
$endPos = $registry.IndexOf($endMarker)
if ($startPos -lt 0 -or $endPos -lt 0 -or $endPos -le $startPos) {
    throw "Registry markers not found in src-zig/commands/registry.zig (expected @modules markers)"
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
