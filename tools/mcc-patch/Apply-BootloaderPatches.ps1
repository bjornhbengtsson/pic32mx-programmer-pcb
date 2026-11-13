# Re-apply this board's bootloader changes after MCC "Generate".
#
# MCC regenerates the Harmony bootloader sources and can undo changes that
# the board needs. Run this after every Generate, then rebuild:
#
#   powershell -ExecutionPolicy Bypass -File tools\mcc-patch\Apply-BootloaderPatches.ps1 -ProjectSrc C:\path\to\MPLABXProjects\src
#
# It is safe to run more than once: settings that are already right are left alone.
#
# What it enforces (all found during hardware bring-up, 2026-11-13):
#   initialization.c        FNOSC = PRIPLL, POSCMOD = HS   (USB needs the 8 MHz crystal)
#                           ICESEL = ICS_PGx2              (board ICSP is PGEC2/PGED2)
#   usb_device_init_data.c  Product ID 0x003C
#   btl.ld                  RAM starts at 0xA0000010 (16-byte app->bootloader request area)
#   src/app.c, src/bootloader_board.h
#                           copied from firmware/bootloader/source_overrides
#                           (T2 update button, RAM request, LED2 status)
# Then it runs scripts/verify_project.py if Python is available.

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectSrc
)

$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$overrides = Join-Path $repo "firmware\bootloader\source_overrides"
$src = (Resolve-Path $ProjectSrc).Path
$cfg = Join-Path $src "config\default"
$script:failed = $false

function Ok([string]$t)   { Write-Host "   OK       $t" -ForegroundColor Green }
function Fix([string]$t)  { Write-Host "   CHANGED  $t" -ForegroundColor Yellow }
function Bad([string]$t)  { Write-Host "   MISSING  $t" -ForegroundColor Red; $script:failed = $true }

# Replace the first regex match in a file. $want is the full desired text of the match.
function Set-Pattern([string]$file, [string]$pattern, [string]$want, [string]$what) {
    if (-not (Test-Path $file)) { Bad "$what ($file not found)"; return }
    $text = [IO.File]::ReadAllText($file)
    $m = [regex]::Match($text, $pattern, "Multiline")
    if (-not $m.Success) { Bad "$what (pattern not found in $(Split-Path $file -Leaf))"; return }
    if ($m.Value -eq $want) { Ok $what; return }
    $text = $text.Substring(0, $m.Index) + $want + $text.Substring($m.Index + $m.Length)
    [IO.File]::WriteAllText($file, $text)
    Fix "$what   (was: $($m.Value.Trim()))"
}

function Copy-Override([string]$name, [string]$dest) {
    $from = Join-Path $overrides $name
    if ((Test-Path $dest) -and ((Get-FileHash $from).Hash -eq (Get-FileHash $dest).Hash)) { Ok "$(Split-Path $dest -Leaf) matches source_overrides\$name"; return }
    Copy-Item $from $dest -Force
    Fix "$(Split-Path $dest -Leaf) <- source_overrides\$name"
}

Write-Host "Re-applying bootloader changes to: $src" -ForegroundColor White
Write-Host ""

$init = Join-Path $cfg "initialization.c"
Set-Pattern $init '#pragma config FNOSC\s*=\s*\w+'   '#pragma config FNOSC =      PRIPLL'   "Clock source FNOSC = PRIPLL"
Set-Pattern $init '#pragma config POSCMOD\s*=\s*\w+' '#pragma config POSCMOD =    HS'       "Primary oscillator POSCMOD = HS"
Set-Pattern $init '#pragma config ICESEL\s*=\s*\w+'  '#pragma config ICESEL =     ICS_PGx2' "Debug channel ICESEL = ICS_PGx2"

Set-Pattern (Join-Path $cfg "usb_device_init_data.c") '0x[0-9A-Fa-f]{4},(?=\s*//\s*Product ID)' '0x003C,' "USB Product ID 0x003C"

$ld = Join-Path $cfg "btl.ld"
Set-Pattern $ld 'kseg1_data_mem\s*\(w!x\)\s*:\s*ORIGIN\s*=\s*0x[0-9A-Fa-f]+\s*,\s*LENGTH\s*=\s*0x[0-9A-Fa-f]+' `
               'kseg1_data_mem       (w!x)  : ORIGIN = 0xA0000010, LENGTH = 0x3FF0' "btl.ld RAM starts at 0xA0000010"
Set-Pattern $ld '_bmxdudba_address\s*=\s*[^;]+;' '_bmxdudba_address = 0x4000 ;' "btl.ld _bmxdudba_address"
Set-Pattern $ld '_bmxdupba_address\s*=\s*[^;]+;' '_bmxdupba_address = 0x4000 ;' "btl.ld _bmxdupba_address"

Copy-Override "bootloader_app.c"   (Join-Path $src "app.c")
Copy-Override "bootloader_board.h" (Join-Path $src "bootloader_board.h")

Write-Host ""
$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
    & $py.Source -I (Join-Path $repo "firmware\bootloader\scripts\verify_project.py") --bootloader $src
    if ($LASTEXITCODE -ne 0) { $script:failed = $true }
} else {
    Write-Host "   (Python not found: skipped verify_project.py)" -ForegroundColor Yellow
}

Write-Host ""
if ($script:failed) {
    Write-Host "Something is missing or failed above. Fix it before building." -ForegroundColor Red
    exit 1
}
Write-Host "Done. Now Clean and Build the bootloader, then check the hex with hex_layout.py." -ForegroundColor Green
