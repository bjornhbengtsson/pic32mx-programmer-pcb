# Validation status

## What was checked before delivery

- The memory map was derived from the target's 64 KiB Program Flash and 16 KiB SRAM.
- The 32 KiB bootloader reservation follows Microchip's PIC32MX USB HID example.
- The application reset page and EBASE split follows Microchip's generated PIC32MX application linker:
  - application jump/reset page at `0x9D008000`
  - EBASE/code at `0x9D009000`
- The first 16 SRAM bytes are reserved for the standard `0x5048434D` boot request.
- The ICSP mapping uses PGEC2/PGED2 (RB6/RB7) and matches `ICESEL = ICS_PGx2`. (Corrected 2026-11-13 from the schematic; an earlier draft said PGEC1/PGED1.)
- The 8 MHz oscillator configuration produces 80 MHz SYSCLK and the required 48 MHz USB clock.
- The trigger override compiles and passes host unit tests.
- The HEX parser passes valid/invalid synthetic image tests.
- Static scripts reject stale 512 KiB/64 KiB-RAM reference settings.

## What was not possible in this environment

- Running MPLAB XC32
- Running MCC/Harmony code generation
- Compiling the final generated MPLAB projects
- Programming a physical PIC32MX534F064H
- Measuring oscillator or USB electrical behavior
- Confirming the exact board LED and switch GPIOs from the low-resolution schematic image
- Pushing directly to the GitHub repository

## Release gate

Do not tag this firmware as hardware-validated until all items below are complete:

- [x] Bootloader project generated for exact device (MCC, Harmony 3 bootloader v3.9.0)
- [x] Bootloader XC32 production build passes (XC32 v5.10)
- [x] Test application XC32 build passes (`firmware/test_app`, built with XC32 directly)
- [x] Static project verification passes (bootloader and test app)
- [x] Both HEX layout checks pass
- [ ] PICkit 4 program/verify passes (not tried)
- [x] Snap program/verify passes
- [x] USB HID enumerates as `04D8:003C`
- [x] Unified Host programs and verifies the test application
- [x] Test application runs after reset and power cycle (USB unplugged and replugged)
- [ ] RAM trigger returns to bootloader (both sides reserve the RAM; not yet tested with an app that requests it)
- [x] Hardware switch trigger passes: **T2** (RB0) + RESET enters update mode. T1 cannot be used (see below).
- [x] ICSP recovery passes: bootloader reflashed over an installed app, USB update mode returned

## Hardware bring-up results (2026-11-13)

Setup: MPLAB Snap (firmware 02.04.55) on the Programmer Port (J2), MPLAB IPE
v6.30, PIC32MX_DFP 1.7.380, board powered from its own USB connector, chip in
the clamshell socket.

| Check | Result |
|---|---|
| ICSP device detection | PASS: `Target device PIC32MX534F064H found`, Device ID `0x4400000`, revision `0xA2` |
| Bootloader program/verify (Snap, IPE) | PASS: checksum `FF122BCA`, `Programming/Verify complete` |
| 8 MHz crystal + PLL | PASS, inferred: USB enumerates, which needs the crystal-fed 48 MHz USB clock. Not measured with a scope. |
| USB enumeration | PASS with caveat: HID device `USB\VID_04D8&PID_0000` |
| Unified Host connection | PASS: `HID device PID: 00 Connected` (Unified Host v1.19.3) |
| USB upload of test app | PASS: erase/write/verify completed |
| Test app runs | PASS: LED1 (RD4) and LED2 (RD1) alternate |

Problems found and fixed during bring-up:

1. **USB had no clock.** MCC generated `FNOSC = FRCPLL` and `POSCMOD = OFF`.
   The USB PLL on PIC32MX5xx only takes the primary oscillator, so the first
   build could never enumerate. Fixed to `PRIPLL` / `HS`;
   `verify_project.py` now rejects the bad settings.
2. **ICSP channel was documented wrong.** The schematic routes J2 to RB6/RB7
   (PGEC2/PGED2, pins 17/18), not PGEC1/PGED1. The docs, `config_bits_8mhz.c`,
   and `verify_project.py` now say `ICS_PGx2`.
3. **XC32 placed a debug stub in Boot Flash for the app.** `._debug_exception`
   lands at `0xBFC00480`. The test-app linker script discards it, and
   `hex_layout.py` caught it.
4. **IPE GUI Snap power-page bug** and **Hold In Reset after programming**.
   Workarounds are in `PROGRAM_WITH_PICKIT4_OR_SNAP.md`.

### Second bootloader build (same day)

Changes: `bootloader_app.c` / `bootloader_board.h` from `source_overrides`
(force-boot switch, RAM request trigger, LED2 status), PID `0x003C`, first 16
bytes of SRAM reserved in `btl.ld`, `ICS_PGx2`. Image: IPE checksum `FF12BE4E`,
now in `firmware/prebuilt/`.

| Check | Result |
|---|---|
| `verify_project.py --bootloader` | PASS |
| `hex_layout.py --mode bootloader` | PASS |
| Host unit tests (RAM trigger + switch + LED) | PASS |
| Program/verify through Snap (`ipecmd`) | PASS |
| USB enumeration, blank app area | PASS: `USB\VID_04D8&PID_003C` |
| Unified Host connection | PASS: `HID device PID: 3C Connected` |
| USB upload of test app (with 16-byte RAM reservation) | PASS: `Disconnected after Programming was Successful.` LEDs alternate |
| Test E: unplug/replug USB | PASS: app starts by itself |
| Test D: hold T1 + tap RESET | **FAIL**: app keeps running (see hardware issue) |
| Test D: hold T2 + tap RESET | PASS: LED2 steady, `PID_003C` back on USB |
| Test F: reflash bootloader over an installed app | PASS: update mode returns |

### Hardware issue: T1 is not connected to the MCU

In the schematic netlist (exported PDF), the `RB4/T1` net contains only MCU
pin 12 (RB4). The T1 switch, its R1 pull-up, R15 and MCP2561 pin 5 (SPLIT) form
a separate net. So T1 never reaches the MCU and RB4 floats, and pressing T1
pulls the CAN transceiver's SPLIT pin to ground. On hardware, holding T1 had no
effect. The bootloader uses **T2 (RB0, pin 16)** instead, which is wired as
expected (R2 pull-up).

**Confirmed with a continuity meter (2026-11-13):** T2 pad → MCU pin 16 (RB0)
beeps; T1 pad → MCU pin 12 (RB4) is open. Fix the `RB4/T1` net label in the
next PCB revision.

Open items:

- Test C: have an application write the RAM request pattern and reset; confirm
  it returns to update mode. (The bootloader and test-app linker scripts both
  reserve the area now.)
- Make the same changes in MCC so a regenerate keeps them: clock `PRIPLL`/`HS`,
  Product ID `0x003C`, `ICS_PGx2`, and the `btl.ld` RAM reservation (MCC does
  not generate it; re-apply after Generate).
- Fix the T1 net in the PCB design.
- PICkit 4 program/verify (only the Snap was used).
- Measure 3.3 V, VCAP, and the crystal frequency for the evidence list.
