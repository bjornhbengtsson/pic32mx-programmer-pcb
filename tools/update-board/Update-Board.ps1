# Update Board: opens Microchip Unified Host for the PIC32MX534 programmer PCB.
#
# Double-click "Update Board.cmd" next to this file instead of running it directly.
#
# What it does:
#   1. Checks whether the board's USB bootloader is connected (VID 04D8, PID 003C).
#      If not, it tells you how to put the board into update mode and waits.
#   2. Finds Java (MPLAB X's bundled copy, or Java on PATH).
#   3. Finds Unified Host (installed with MPLAB Harmony 3 / MCC) and opens it.

param(
    [string]$UnifiedHostJar = "",
    [switch]$NoWait
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$text) { Write-Host ""; Write-Host "== $text" -ForegroundColor Cyan }
function Write-Ok([string]$text)   { Write-Host "   OK  $text" -ForegroundColor Green }
function Write-Bad([string]$text)  { Write-Host "   !!  $text" -ForegroundColor Yellow }

function Test-BootloaderConnected {
    $dev = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -like 'USB\VID_04D8&PID_003C*' -and $_.Status -eq 'OK' }
    return [bool]$dev
}

function Find-Java {
    $candidates = @()
    foreach ($root in @("$env:ProgramFiles\Microchip\MPLABX", "${env:ProgramFiles(x86)}\Microchip\MPLABX")) {
        if (Test-Path $root) {
            $candidates += Get-ChildItem $root -Recurse -Depth 6 -Filter javaw.exe -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '\\sys\\java\\' } |
                Sort-Object FullName -Descending | Select-Object -ExpandProperty FullName
        }
    }
    $onPath = Get-Command javaw.exe -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    return $candidates | Select-Object -First 1
}

function Find-UnifiedHost {
    $roots = @(
        "$env:USERPROFILE\.mcc\harmony\content\bootloader",
        "$env:USERPROFILE\Harmony3\bootloader",
        "C:\microchip\harmony\v3\bootloader"
    ) | Where-Object { Test-Path $_ }
    $jars = foreach ($r in $roots) {
        Get-ChildItem $r -Recurse -Depth 4 -Filter "UnifiedHost-*.jar" -ErrorAction SilentlyContinue
    }
    # Newest version first.
    return $jars | Sort-Object { [version](($_.BaseName -replace '^UnifiedHost-', '') -replace '[^0-9.]', '') } -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

Write-Host "PIC32MX534 programmer PCB - Update Board" -ForegroundColor White

# 1. Board in update mode?
Write-Step "Step 1: Is the board in update mode?"
if (Test-BootloaderConnected) {
    Write-Ok "Board bootloader found on USB (VID 04D8, PID 003C)."
}
else {
    Write-Bad "The board is not in update mode yet."
    Write-Host ""
    Write-Host "   Put it in update mode:"
    Write-Host "     1. Plug the board's USB cable into this PC."
    Write-Host "     2. Press and HOLD button T2  (not T1 - T1 is not wired)."
    Write-Host "     3. While holding T2, tap the RESET button (T3)."
    Write-Host "     4. Let go of T2."
    Write-Host "   LED2 turns on and stays on when the board is in update mode."
    if (-not $NoWait) {
        Write-Host ""
        Write-Host "   Waiting for the board... (press Ctrl+C to cancel)"
        $deadline = (Get-Date).AddMinutes(5)
        while (-not (Test-BootloaderConnected)) {
            if ((Get-Date) -gt $deadline) { throw "No board found after 5 minutes. Check the USB cable and try the button steps again." }
            Start-Sleep -Milliseconds 500
        }
        Write-Ok "Board bootloader found on USB."
    }
}

# 2. Java
Write-Step "Step 2: Find Java"
$java = Find-Java
if (-not $java) { throw "Java not found. Install MPLAB X IDE (it includes Java)." }
Write-Ok $java

# 3. Unified Host
Write-Step "Step 3: Open Unified Host"
if (-not $UnifiedHostJar) { $UnifiedHostJar = Find-UnifiedHost }
if (-not $UnifiedHostJar -or -not (Test-Path $UnifiedHostJar)) {
    throw "Unified Host not found. Open MPLAB X > MCC once with the Harmony 'bootloader' package installed, or pass -UnifiedHostJar <path>."
}
Write-Ok $UnifiedHostJar

Start-Process -FilePath $java -ArgumentList @('-jar', "`"$UnifiedHostJar`"") -WorkingDirectory (Split-Path $UnifiedHostJar)

Write-Host ""
Write-Host "In Unified Host (it does not remember these, so set them every time):" -ForegroundColor White
Write-Host "  1. Device Architecture: PIC32MK\PIC32MX\PIC32MZ\SAM MCUs"
Write-Host "  2. Protocol: USB   -> it should say 'HID device PID: 3C Connected'"
Write-Host "     (if it shows another PID: Configure > Product ID = 3C)"
Write-Host "  3. File > Open Hex File > choose your application .hex"
Write-Host "  4. Click Program Device. When it finishes, the board restarts into your app."
