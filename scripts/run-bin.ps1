param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$binOpt = "-Dbin=$Name"

if ($Args -and $Args.Count -gt 0) {
    & zig build run-bin $binOpt -- @Args
} else {
    & zig build run-bin $binOpt
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
