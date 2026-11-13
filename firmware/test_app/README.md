# LED test application (USB-bootloader-aware)

A minimal bare-metal application for proving the USB HID bootloader end to end.
It alternates the board's two LEDs every 250 ms.

| LED | Pin | Drive |
|---|---|---|
| LED1 | RD4 | active-high, 4.7 kΩ |
| LED2 | RD1 | active-high, 4.7 kΩ |

This was the first application loaded over USB with Microchip Unified Host on
2026-11-13, and it ran on the board.

## Files

| File | Purpose |
|---|---|
| `main.c` | LED blink using the core timer. Sets **no** config bits. |
| `app_mx534.ld` | Linker script that places the app above the 32 KiB bootloader. |
| `build.ps1` | Builds `test_app_pic32mx534.hex` with XC32 from the command line. |

A prebuilt hex is in [`../prebuilt/`](../prebuilt/).

## Memory layout

`app_mx534.ld` is derived from the Harmony-generated bootloader linker script
for this device, with these changes:

| Region | Address | Notes |
|---|---|---|
| Reset page | `0xBD008000` (phys `0x1D008000`), 0x490 | Bootloader jumps to `0x9D008000`, the same physical address |
| Exception vectors / EBASE | `0x9D009000`, 0x1000 | |
| Code | `0x9D00A000`, 0x6000 | Ends at the top of Program Flash, `0x9D00FFFF` |
| SRAM | `0xA0000010`, 0x3FF0 | First 16 bytes reserved for the bootloader request pattern |
| Config words | none | The bootloader owns them |
| `._debug_exception` | discarded | XC32 hard-places this stub at `0xBFC00480` in Boot Flash. Keeping it would make the app overwrite part of the bootloader. |

The app relies on the bootloader's clock: 8 MHz crystal → PLL → 80 MHz SYSCLK,
so the core timer runs at 40 MHz.

## Build

Requires MPLAB X v6.30 and XC32 v5.10 (other versions likely work; adjust the
paths in `build.ps1`).

```powershell
powershell -ExecutionPolicy Bypass -File firmware\test_app\build.ps1
```

Always check the result before uploading it:

```powershell
python firmware\bootloader\scripts\hex_layout.py --mode application firmware\test_app\test_app_pic32mx534.hex
python firmware\bootloader\scripts\verify_project.py --application firmware\test_app
```

Both must report `PASS`.

## Load over USB

1. Make sure the bootloader is running (blank app area, or reprogram the
   bootloader with the Snap/PICkit). Windows shows a HID device with VID `04D8`.
2. Open Microchip Unified Host (shipped with Harmony 3 under
   `bootloader/tools/UnifiedHost-*/`). Architecture: PIC32, Protocol: USB.
   It should report `HID device PID: … Connected`.
3. **File → Open Hex File**, choose `test_app_pic32mx534.hex`.
4. Click **Program Device**. After erase/write/verify the board resets and the
   LEDs start alternating.

Once an app is installed the board boots straight into it. Until a force-boot
button or software request is wired up, use ICSP (Snap/PICkit) to get back to
the bootloader.
