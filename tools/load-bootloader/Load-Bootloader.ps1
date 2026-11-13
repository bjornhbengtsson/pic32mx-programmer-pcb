# Load Bootloader: puts the USB bootloader on PIC32MX534F064H chips, one after another.
#
# Double-click "Load Bootloader.cmd" next to this file instead of running it directly.
#
# For each chip it:
#   1. programs and verifies the bootloader through an MPLAB Snap (or PICkit 4),
#   2. optionally runs the LED test (bootloader + LED app), then removes the app,
#   3. checks over USB that the bootloader is actually running (04D8:003C),
#   4. writes a line to logs\load-bootloader-<date>.csv.
#
# Chips leave with ONLY the bootloader, so they start in update mode on any board.

param(
    [ValidateSet("Snap", "PICkit4")]
    [string]$Tool = "Snap",
    [string]$IpeCmd = ""
)

$ErrorActionPreference = "Stop"
$Device = "32MX534F064H"

# ---------------------------------------------------------------- helpers
function Say([string]$t, [string]$c = "Gray") { Write-Host $t -ForegroundColor $c }
function Title([string]$t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Cyan }
function Ok([string]$t)    { Write-Host "   OK    $t" -ForegroundColor Green }
function Bad([string]$t)   { Write-Host "   FAIL  $t" -ForegroundColor Red }
function Warn([string]$t)  { Write-Host "   NOTE  $t" -ForegroundColor Yellow }
function Ask([string]$q)   { Write-Host ""; return (Read-Host $q).Trim() }
function Stop-Here([string]$msg) {
    Write-Host ""; Bad $msg; Write-Host ""
    exit 1
}

function Get-UsbPresent([string]$pattern) {
    [bool](Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -like $pattern -and $_.Status -eq "OK" })
}

function Wait-Usb([string]$pattern, [int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $deadline) {
        if (Get-UsbPresent $pattern) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Explain-Failure([string]$out) {
    Say ""
    Say "   What to check:" White
    if ($out -notmatch "Target device .* found") {
        Say "   - The Snap could not see the chip:"
        Say "       * Is the chip seated with its pin-1 dot on the socket's pin-1 mark, and the lid fully latched?"
        Say "       * Is the board powered? (board USB plugged in, power LED on)"
        Say "       * Is the Snap's arrow (pin 1) on the MCLR end of the Programmer Port (J2), pushed fully on?"
        Say "       * Try another chip. A chip with bent pins will not be detected."
    }
    if ($out -match "(?i)voltage|vdd") {
        Say "   - Voltage problem: the board is not powered, or the Snap is not making contact on J2 pins 2/3."
    }
    if ($out -match "(?i)Erase.*Failed|Programming.*Failed|in use|busy") {
        Say "   - Another program may be using the Snap. Close MPLAB IPE / MPLAB X and try again."
    }
    if ($out -match "(?i)Verify.*Failed|Verify Failed") {
        Say "   - Verify failed: reseat the chip and run it again. If it fails twice, set the chip aside."
    }
    if ($out -match "(?i)no tool|not found.*tool|Unable to connect|Failed to get.*tool|Tool.*not") {
        Say "   - The Snap itself was not found: check its micro-USB cable to the PC."
    }
}

function Invoke-Ipe([string]$hex, [string]$label) {
    Say "   $label ... (about 20-40 seconds)"
    $toolArg = if ($Tool -eq "PICkit4") { "-TPPK4" } else { "-TPSNAP" }
    Push-Location $env:TEMP
    try {
        $out = & $script:IpeCmd $toolArg "-P$Device" "-F$hex" "-M" "-Y" "-OL" 2>&1 | Out-String
        $code = $LASTEXITCODE
    } finally { Pop-Location }
    Add-Content -Path $script:RawLog -Value "----- $(Get-Date -Format s) $label (exit $code)`r`n$out"
    $okProg = $out -match "Program Succeeded"
    $okVer  = $out -match "Verify Succeeded"
    $sum = if ($out -match "Checksum\s*=\s*([0-9A-Fa-f]+)") { $Matches[1] } else { "" }
    return [pscustomobject]@{ Ok = ($code -eq 0 -and $okProg -and $okVer); Out = $out; Code = $code; Checksum = $sum }
}

# ---------------------------------------------------------------- setup checks
Clear-Host
Say "PIC32MX534 - Load Bootloader" White
Say "Loads the USB bootloader onto chips in the clamshell socket, one after another."

$repo     = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$prebuilt = Join-Path $repo "firmware\prebuilt"
$bootHex  = Join-Path $prebuilt "bootloader_pic32mx534.hex"
$ledHex   = Join-Path $prebuilt "bootloader_plus_led_test.hex"
$sums     = Join-Path $prebuilt "SHA256SUMS.txt"
$logDir   = Join-Path $repo "logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp    = Get-Date -Format "yyyy-MM-dd"
$CsvLog   = Join-Path $logDir "load-bootloader-$stamp.csv"
$RawLog   = Join-Path $logDir "load-bootloader-$stamp-ipecmd.txt"

Title "Checking this PC"

# Firmware files present and unmodified
foreach ($f in @($bootHex, $ledHex)) {
    if (-not (Test-Path $f)) { Stop-Here "Missing $f. Download the whole repository again (see the Lab Tech guide)." }
}
if (Test-Path $sums) {
    foreach ($line in Get-Content $sums) {
        if ($line -match "^([0-9a-f]{64})\s+\*?(\S+)$") {
            $expect = $Matches[1]; $name = $Matches[2]
            $p = Join-Path $prebuilt $name
            if (Test-Path $p) {
                $got = (Get-FileHash $p -Algorithm SHA256).Hash.ToLower()
                if ($got -ne $expect) { Stop-Here "$name does not match SHA256SUMS.txt (file changed or damaged). Download the repository again." }
            }
        }
    }
    Ok "Firmware files found and checked"
} else { Warn "SHA256SUMS.txt not found; skipping file check" }

# ipecmd
if (-not $IpeCmd) {
    $IpeCmd = Get-ChildItem "$env:ProgramFiles\Microchip\MPLABX" -Recurse -Depth 5 -Filter ipecmd.exe -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $IpeCmd -or -not (Test-Path $IpeCmd)) { Stop-Here "MPLAB IPE not found. Install MPLAB X IDE with MPLAB IPE (see the Lab Tech guide)." }
$script:IpeCmd = $IpeCmd
Ok "MPLAB IPE command line: $IpeCmd"

# IPE / MPLAB X windows hold the Snap
$holders = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match "MPLAB IPE|MPLAB X IDE" }
if ($holders) {
    Warn "MPLAB IPE or MPLAB X is open. It can lock the Snap."
    $a = Ask "   Close it now, then press Enter (or type S to skip this check)"
}

# Snap on USB
if ($Tool -eq "Snap") {
    if (Get-UsbPresent 'USB\VID_04D8&PID_9018*') { Ok "MPLAB Snap found on USB" }
    else {
        Bad "MPLAB Snap not found on USB."
        Say "   Plug the Snap's micro-USB cable into this PC. Its light should come on."
        if (-not (Wait-Usb 'USB\VID_04D8&PID_9018*' 60)) { Stop-Here "Still no Snap after 60 seconds." }
        Ok "MPLAB Snap found on USB"
    }
}

# Mode
Title "Choose a mode"
Say "   1  Load bootloader                    (normal, ~1 minute per chip)"
Say "   2  Load bootloader + LED test         (first chip of the day, or a chip you doubt; ~2 minutes)"
Say "   3  Load bootloader + LED app, KEEP it (chips start blinking RD4/RD1 on power-up; ~1 minute)"
Say ""
Say "   Mode 1 and 2 chips start in update mode. Mode 3 chips start the LED app instead:"
Say "   students then need the RB0 update button (or a Snap) to load their own code."
$mode = Ask "   Type 1, 2 or 3 and press Enter"
if ($mode -notin @("2", "3")) { $mode = "1" }
if ($mode -eq "3") { Warn "Mode 3: chips leave with the LED app installed." }

if (-not (Test-Path $CsvLog)) { "time,chip,mode,checksum,led_test,usb_check,result" | Set-Content $CsvLog }

# ---------------------------------------------------------------- per-chip loop
$n = 0; $pass = 0; $fail = 0
while ($true) {
    $n++
    Title "Chip $n"
    Say "   1. Unplug the board's USB cable (power off before opening the socket)."
    Say "   2. Open the clamshell. Remove the previous chip (put it in the DONE tray)."
    Say "   3. Insert a new chip: pin-1 dot on the socket's pin-1 mark. Close and latch the lid."
    Say "   4. Plug the board's USB cable back into THIS PC."
    $a = Ask "   Press Enter when ready (or type Q to finish)"
    if ($a -match "^[Qq]") { $n--; break }

    $led = "skipped"; $usb = "not checked"; $result = "FAIL"; $sum = ""

    if ($mode -eq "3") {
        # Ship with the LED app: the LED check is the proof the chip runs.
        $r = Invoke-Ipe $ledHex "Programming bootloader + LED app"
        $sum = $r.Checksum
        if (-not $r.Ok) { Bad "Programming failed."; Explain-Failure $r.Out }
        else {
            Ok "Programmed and verified (bootloader + LED app, checksum $sum)"
            $a = Ask "   Look at the board: are LED1 and LED2 taking turns blinking? (Y/N)"
            $led = if ($a -match "^[Yy]") { "pass" } else { "fail" }
            if ($led -eq "pass") { $result = "PASS"; Ok "LED app running" }
            else { Bad "LEDs not blinking: the chip programs but the app does not run. Reseat the chip and run it again." }
        }
        $usb = "n/a (app installed)"
        if ($result -eq "PASS") { $pass++; Say ""; Say "   >>> CHIP $n PASS (LED app installed) - put it in the DONE tray <<<" Green }
        else { $fail++; Say ""; Say "   >>> CHIP $n FAIL - set it aside, then try it once more <<<" Red }
        "$(Get-Date -Format s),$n,$mode,$sum,$led,$usb,$result" | Add-Content $CsvLog
        continue
    }

    if ($mode -eq "2") {
        $r = Invoke-Ipe $ledHex "Programming bootloader + LED test"
        if (-not $r.Ok) { Bad "Programming failed."; Explain-Failure $r.Out }
        else {
            Ok "Programmed and verified (bootloader + LED test)"
            $a = Ask "   Look at the board: are LED1 and LED2 taking turns blinking? (Y/N)"
            $led = if ($a -match "^[Yy]") { "pass" } else { "fail" }
            if ($led -eq "fail") { Bad "LED test failed: the chip programs but the app does not run. Check the 8 MHz crystal area and reseat the chip." }
            else { Ok "LED test passed" }
        }
        if (-not $r.Ok) { $fail++; "$(Get-Date -Format s),$n,$mode,,$led,$usb,FAIL" | Add-Content $CsvLog; continue }
    }

    $r = Invoke-Ipe $bootHex "Programming bootloader"
    $sum = $r.Checksum
    if (-not $r.Ok) {
        Bad "Programming failed."
        Explain-Failure $r.Out
    } else {
        Ok "Programmed and verified (checksum $sum)"
        Say "   Checking that the bootloader starts and shows up on USB..."
        if (Wait-Usb 'USB\VID_04D8&PID_003C*' 15) {
            $usb = "pass"; Ok "Bootloader running: USB 04D8:003C found. LED2 should be on steady."
        } else {
            $usb = "fail"
            Bad "Bootloader did not show up on USB within 15 seconds."
            Say "   - Is the board's USB cable plugged into THIS PC (not a wall charger)? Is it a data cable?"
            Say "   - Is LED2 on? If not, the chip may not be running: reseat it and run it again."
        }
        if ($usb -eq "pass" -and $led -ne "fail") { $result = "PASS" }
    }

    if ($result -eq "PASS") { $pass++; Say ""; Say "   >>> CHIP $n PASS - mark it and put it in the DONE tray <<<" Green }
    else { $fail++; Say ""; Say "   >>> CHIP $n FAIL - set it aside, then try it once more <<<" Red }
    "$(Get-Date -Format s),$n,$mode,$sum,$led,$usb,$result" | Add-Content $CsvLog
}

Title "Summary"
Say "   Chips tried: $n   PASS: $pass   FAIL: $fail" White
Say "   Log: $CsvLog"
Say "   Unplug the board's USB cable before removing the last chip."
