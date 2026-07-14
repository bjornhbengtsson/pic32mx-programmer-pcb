[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$repo = (Resolve-Path $Repository).Path
$package = (Resolve-Path $PackageRoot).Path
$destination = Join-Path $repo "firmware\bootloader"

if (-not (Test-Path (Join-Path $repo ".git"))) {
    throw "Not a Git repository: $repo"
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null

$gitkeep = Join-Path $destination ".gitkeep"
if (Test-Path $gitkeep) {
    Remove-Item $gitkeep
}

Get-ChildItem $package -Force |
    Where-Object { $_.Name -ne "pic32mx534_usb_hid_bootloader.zip" } |
    Copy-Item -Destination $destination -Recurse -Force

Write-Host "Installed package into: $destination"
Write-Host ""
Write-Host "Review, then run:"
Write-Host "  cd `"$repo`""
Write-Host "  git add firmware/bootloader"
Write-Host "  git commit -m `"Add PIC32MX534 USB HID bootloader firmware and guide`""
Write-Host "  git push origin main"
