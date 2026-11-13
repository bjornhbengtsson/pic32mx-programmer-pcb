# Firmware

Firmware for the PIC32MX534F064H programmer and validation board.

## Directories

- `bootloader/` — USB HID bootloader: build guide, source overrides, checks, and validation docs
- `test_app/` — bare-metal LED test application loaded over USB by the bootloader
- `prebuilt/` — ready-to-flash bootloader and test-app hex files with SHA-256 sums

MPLAB build outputs, private IDE settings, object files, and generated binaries are excluded through the repository `.gitignore`. The only hex files tracked are the released images in `prebuilt/`.
