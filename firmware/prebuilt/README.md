# Prebuilt firmware

Ready-to-flash images for the PIC32MX534F064H programmer PCB.

| File | Load with | Status |
|---|---|---|
| `bootloader_pic32mx534.hex` | ICSP only: MPLAB Snap or PICkit 4 via MPLAB IPE | Programmed, verified, and enumerated over USB on 2026-11-13 |
| `test_app_pic32mx534.hex` | USB only: Microchip Unified Host | Built from `firmware/test_app`. See the note below. |

Never load the bootloader hex through Unified Host, and never load an
application hex through ICSP on top of the bootloader without erasing first.

## SHA-256

```text
457f2969d13edb2a8e940e768c24f39395b1b6a21b6064ab6cacc31319f21d0f  bootloader_pic32mx534.hex
ef4000bb173f6373600ea198f1ccdc6527f0379c42a222daf8cb5b7459ae11b1  test_app_pic32mx534.hex
```

## Bootloader image

- Harmony 3 USB Device HID bootloader generated with MCC for PIC32MX534F064H,
  built with XC32 v5.10, PIC32MX_DFP 1.6.369.
- IPE checksum: `FF122BCA`.
- Clock: `FNOSC = PRIPLL`, `POSCMOD = HS`, 8 MHz crystal → 80 MHz SYSCLK,
  48 MHz USB.
- Occupies `0x1D000000`–`0x1D005398` plus Boot Flash and config words. The
  application area at `0x1D008000` and up is left blank.
- USB: VID `0x04D8`, **PID `0x0000`**. MCC left the product ID blank. Unified
  Host connects to it as-is; set it to `0x003C` in MCC for the next build.
- `ICESEL` in this image is `ICS_PGx1`. That only affects hardware debugging;
  the board's Programmer Port is wired to PGEC2/PGED2, so rebuild with
  `ICS_PGx2` before debugging the bootloader in MPLAB X.
- Known gap: the generated linker script does not reserve the first 16 bytes of
  SRAM for the boot-request pattern, so the application-triggered return to the
  bootloader (validation Test C) is not expected to work with this image.

## Test application image

The image that ran on the board on 2026-11-13 was built from the same
`main.c`, before the linker script was changed to reserve the first 16 bytes of
SRAM. The image here includes that reservation. Code and flash layout are
otherwise the same, but this exact file has not yet been loaded on hardware.

## Check before flashing

```powershell
python firmware\bootloader\scripts\hex_layout.py --mode bootloader  firmware\prebuilt\bootloader_pic32mx534.hex
python firmware\bootloader\scripts\hex_layout.py --mode application firmware\prebuilt\test_app_pic32mx534.hex
```
