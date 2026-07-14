[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("PICkit4", "Snap")]
    [string]$Tool,

    [Parameter(Mandatory = $true)]
    [string]$Hex,

    [string]$IpeCmd
)

$ErrorActionPreference = "Stop"

$hexPath = (Resolve-Path $Hex).Path

if (-not $IpeCmd) {
    $candidates = Get-ChildItem `
        "C:\Program Files\Microchip\MPLABX" `
        -Filter ipecmd.exe `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending

    if (-not $candidates) {
        throw "ipecmd.exe not found. Pass -IpeCmd with its full path."
    }

    $IpeCmd = $candidates[0].FullName
}

if (-not (Test-Path $IpeCmd)) {
    throw "IPECMD executable not found: $IpeCmd"
}

$toolArgument = switch ($Tool) {
    "PICkit4" { "-TPPK4" }
    "Snap"    { "-TPSNAP" }
}

$arguments = @(
    $toolArgument,
    "-P32MX534F064H",
    "-F$hexPath",
    "-E",
    "-M",
    "-Y",
    "-OL"
)

Write-Host "Tool:       $Tool"
Write-Host "Device:     PIC32MX534F064H"
Write-Host "HEX:        $hexPath"
Write-Host "IPECMD:     $IpeCmd"
Write-Host ""
Write-Warning "This command does not power the target. Use regulated external 3.3 V and connect TVDD for sensing."
Write-Host ""

& $IpeCmd @arguments

if ($LASTEXITCODE -ne 0) {
    throw "IPECMD failed with exit code $LASTEXITCODE"
}

Write-Host "Programming and verification completed."
