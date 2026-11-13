@echo off
rem Double-click this file to put new firmware on the PIC32MX534 programmer PCB.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Board.ps1" %*
echo.
pause
