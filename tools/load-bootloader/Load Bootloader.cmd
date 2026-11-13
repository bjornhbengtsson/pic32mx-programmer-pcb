@echo off
rem Double-click to load the USB bootloader onto PIC32MX534F064H chips with an MPLAB Snap.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Load-Bootloader.ps1" %*
echo.
pause
