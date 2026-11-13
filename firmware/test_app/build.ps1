# Build the LED test application with XC32 (no MPLAB X project needed).
# Output: test_app_pic32mx534.hex next to this script.

param(
    [string]$Xc32Bin = "C:\Program Files\Microchip\xc32\v5.10\bin",
    [string]$Dfp     = "C:/Program Files/Microchip/MPLABX/v6.30/packs/Microchip/PIC32MX_DFP/1.6.369"
)

# XC32 prints informational lines on stderr ("Info: Loading file ..."). Windows
# PowerShell 5.1 turns native stderr into errors, so do not use "Stop" here;
# success is judged by each tool's exit code instead.
$ErrorActionPreference = "Continue"
Push-Location $PSScriptRoot
try {
    & "$Xc32Bin\xc32-gcc.exe" -mprocessor=32MX534F064H "-mdfp=$Dfp" -O1 -Wall `
        -o test_app_pic32mx534.elf main.c `
        "-Wl,--script=app_mx534.ld,-Map=test_app_pic32mx534.map,--memorysummary,memoryfile.xml"
    if ($LASTEXITCODE -ne 0) { throw "xc32-gcc failed ($LASTEXITCODE)" }

    & "$Xc32Bin\xc32-bin2hex.exe" test_app_pic32mx534.elf
    if ($LASTEXITCODE -ne 0) { throw "xc32-bin2hex failed ($LASTEXITCODE)" }

    Write-Host "Built $PSScriptRoot\test_app_pic32mx534.hex"
}
finally {
    Pop-Location
}
