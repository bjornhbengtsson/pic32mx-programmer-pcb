# PIC32MX534F064H USB HID Bootloader

This folder is the board-specific integration package for a **PIC32MX534F064H-I/PT** USB Device HID bootloader using:

- MPLAB X IDE
- MPLAB XC32
- MPLAB Code Configurator / Harmony 3
- PICkit 4 (`PG164140`) or MPLAB Snap (`PG164100`) for the one-time ICSP load
- Microchip Unified Host for later USB firmware updates

## Important status

The source in this package is the **board-specific code and reproducible integration recipe** around Microchip's generated Harmony 3 USB HID bootloader. Harmony-generated USB, NVM, interrupt, startup, and linker files must be generated for the exact target device in MPLAB X/MCC.

Completed checks in this package:

- Host compilation and unit testing of the bootloader trigger override
- Intel HEX parser tests
- Static memory-contract checks
- Review against Microchip's PIC32MX USB HID bootloader reference and PIC32MX534F064H memory/pin data

Still required before calling the firmware production-ready:

1. Generate the two MPLAB X projects for `PIC32MX534F064H`.
2. Build both with XC32.
3. Run `scripts/verify_project.py`.
4. Run `scripts/hex_layout.py` on both production HEX files.
5. Program and test a real MCU in the clamshell fixture.
6. Confirm USB enumeration and an application update through Unified Host.

A remote software-only review cannot prove oscillator startup, USB signal integrity, socket contact, power integrity, or ICSP wiring on the physical PCB.

## Assumptions that must match the PCB

| Item | Assumed value |
|---|---|
| MCU | PIC32MX534F064H-I/PT, 64-TQFP |
| Primary oscillator | 8 MHz crystal on OSC1/OSC2 |
| CPU clock | 80 MHz |
| USB clock | 48 MHz from USB PLL |
| ICSP channel | PGEC1/PGED1 |
| Target voltage | 3.3 V |
| Initial programmer | PICkit 4 or MPLAB Snap |
| USB mode | Full-speed USB Device HID |
| USB VID/PID | `0x04D8 / 0x003C` |
| Bootloader PFM reservation | 32 KiB |
| Application download/reset page | `0x9D008000` |
| Application EBASE/code start | `0x9D009000` |
| SRAM | 16 KiB; first 16 bytes reserved for boot request |

The LED and force-boot switch GPIOs could not be read reliably from the supplied schematic image. They are therefore disabled by default in `source_overrides/bootloader_board.h`. Map them to actual MCC-generated pin aliases before hardware validation.

## Folder layout

```text
README.md
BUILD_WITH_MPLAB_HARMONY.md
HARDWARE_SETUP.md
PROGRAM_WITH_PICKIT4_OR_SNAP.md
USB_UPDATE_AND_VALIDATION.md
VALIDATION_STATUS.md
REFERENCES.md
memory_contract.json
source_overrides/
  bootloader_app.c
  bootloader_board.h
  config_bits_8mhz.c
test_app_snippets/
  bootloader_request.c
  bootloader_request.h
  test_app_app.c
  test_app_board.h
scripts/
  hex_layout.py
  verify_project.py
  program_bootloader.ps1
  install_into_repo.ps1
  run_host_checks.py
tests/
  mocks/app.h
  mocks/definitions.h
  test_bootloader_app_host.c
  test_hex_layout.py
generated_projects/
  README.md
```

## Recommended workflow

### 1. Install the development tools

Install MPLAB X IDE, MPLAB XC32, and MCC/Harmony 3. A known Microchip reference combination for this example family is:

- MPLAB X IDE 6.25
- MPLAB XC32 4.60
- MCC 5.5.2

A newer compatible toolchain can be used, but record the exact versions in the commit.

### 2. Obtain the Microchip reference

Clone the official USB bootloader examples:

```powershell
git clone https://github.com/Microchip-MPLAB-Harmony/bootloader_apps_usb.git
```

Use this example as the closest reference:

```text
apps/usb_device_hid_bootloader/
  bootloader/firmware/pic32mx_125_sk.X
  test_app/firmware/pic32mx_125_sk.X
```

Do **not** program that project unchanged. It targets a larger PIC32MX device and has the wrong Flash and RAM sizes for this MCU.

### 3. Generate the target projects

Follow `BUILD_WITH_MPLAB_HARMONY.md`. Create:

```text
generated_projects/
  bootloader_pic32mx534.X/
  test_app_pic32mx534.X/
```

### 4. Replace/add the board-specific sources

For the bootloader project:

- Replace generated `src/app.c` with `source_overrides/bootloader_app.c`.
- Copy `source_overrides/bootloader_board.h` beside `app.c`.
- Add `source_overrides/config_bits_8mhz.c` to Source Files.
- Edit `bootloader_board.h` only after confirming the actual LED/switch pins.

For the test application:

- Replace its generated `src/app.c` with `test_app_snippets/test_app_app.c`.
- Copy `test_app_snippets/test_app_board.h` beside it.
- Add `bootloader_request.c/.h` when the application needs to request bootloader mode.

Do not add configuration-bit pragmas to the USB-loaded application.

### 5. Build and verify

From this folder:

```powershell
python scripts\verify_project.py `
  --bootloader generated_projects\bootloader_pic32mx534.X `
  --application generated_projects\test_app_pic32mx534.X
```

After MPLAB X creates both production HEX files:

```powershell
python scripts\hex_layout.py `
  --mode bootloader `
  generated_projects\bootloader_pic32mx534.X\dist\default\production\bootloader_pic32mx534.X.production.hex

python scripts\hex_layout.py `
  --mode application `
  generated_projects\test_app_pic32mx534.X\dist\default\production\test_app_pic32mx534.X.production.hex
```

Expected result: both commands end with `PASS`.

### 6. Program the one-time bootloader over ICSP

Read `HARDWARE_SETUP.md`, then:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\program_bootloader.ps1 `
  -Tool PICkit4 `
  -Hex generated_projects\bootloader_pic32mx534.X\dist\default\production\bootloader_pic32mx534.X.production.hex
```

For Snap, replace `PICkit4` with `Snap`.

### 7. Load the test application over USB

Follow `USB_UPDATE_AND_VALIDATION.md`.

## Memory map

```text
PIC32MX534F064H Program Flash: 64 KiB

0x9D000000 +------------------------------+
             | USB HID bootloader         |
             | 32 KiB reserved            |
0x9D008000 +------------------------------+
             | Application reset page     |
             | reset entry at 0xBD008000  |
0x9D009000 +------------------------------+
             | Application EBASE, vectors |
             | and normal code            |
0x9D010000 +------------------------------+

SRAM: 16 KiB

0xA0000000 +------------------------------+
             | 16-byte boot request       |
0xA0000010 +------------------------------+
             | Application/bootloader RAM |
0xA0004000 +------------------------------+
```

`0x9D...` and `0xBD...` are cached/uncached virtual aliases of the same physical Program Flash. The first application erase page begins at physical address `0x1D008000`.

## Safety rules

- Never connect an unpowered target to a powered programmer unless the tool documentation explicitly permits that setup.
- Prefer external regulated 3.3 V power and use the programmer's TVDD pin as voltage sense.
- Do not enable programmer target power while USB or another 3.3 V source is already powering the board.
- Pin 1 orientation on the ICSP cable and the clamshell socket must be verified before insertion.
- Do not place capacitors, LEDs, pull-ups, or other loads on PGEC1/PGED1.
- Keep code protection and write protection off until development and recovery testing are complete.
