# Prebuilt firmware

Ready-to-flash images for the PIC32MX534F064H programmer PCB.

| File | Load with | Status |
|---|---|---|
| `bootloader_pic32mx534.hex` | ICSP only: MPLAB Snap or PICkit 4 via MPLAB IPE | Programmed, verified and fully tested on hardware 2026-11-13 |
| `test_app_pic32mx534.hex` | USB only: Microchip Unified Host | Loaded over USB and running on hardware 2026-11-13 |

Never load the bootloader hex through Unified Host, and never load an
application hex through ICSP on top of the bootloader without erasing first.

## SHA-256

```text
040cf36edff104246af912b6ca4ac703bed97fc15ba48671ef1dea494fd72475  bootloader_pic32mx534.hex
ef4000bb173f6373600ea198f1ccdc6527f0379c42a222daf8cb5b7459ae11b1  test_app_pic32mx534.hex
```

## Bootloader image

- Harmony 3 USB Device HID bootloader generated with MCC for PIC32MX534F064H,
  built with XC32 v5.10, PIC32MX_DFP 1.6.369, plus
  `firmware/bootloader/source_overrides/bootloader_app.c` and
  `bootloader_board.h`.
- IPE checksum: `FF12BE4E`.
- Clock: `FNOSC = PRIPLL`, `POSCMOD = HS`, 8 MHz crystal → 80 MHz SYSCLK,
  48 MHz USB. `ICESEL = ICS_PGx2`.
- USB: VID `0x04D8`, PID `0x003C`.
- Enters update mode (LED2 on, steady) when:
  - **T2** (RB0) is held during reset, or
  - the app wrote the `0x5048434D` request to the first 16 bytes of SRAM and
    reset, or
  - no app is installed.
- RAM starts at `0xA0000010`; the first 16 bytes are reserved for that request.
- Occupies `0x1D000000`–`0x1D005xxx` plus Boot Flash and config words. The
  application area at `0x1D008000` and up is left blank.

Earlier image (checksum `FF122BCA`, PID `0x0000`, no button) is superseded.

## Test application image

LED1 (RD4) and LED2 (RD1) alternate every 250 ms. Built from
`firmware/test_app`. This exact file was loaded over USB and ran on
2026-11-13.

## Check before flashing

```powershell
python firmware\bootloader\scripts\hex_layout.py --mode bootloader  firmware\prebuilt\bootloader_pic32mx534.hex
python firmware\bootloader\scripts\hex_layout.py --mode application firmware\prebuilt\test_app_pic32mx534.hex
```
