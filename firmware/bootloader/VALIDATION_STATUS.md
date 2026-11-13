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
- [ ] Static project verification passes: test app PASS; bootloader FAILS the 16-byte SRAM trigger reservation check (see open items)
- [x] Both HEX layout checks pass
- [ ] PICkit 4 program/verify passes (not tried)
- [x] Snap program/verify passes
- [ ] USB HID enumerates as `04D8:003C`: enumerates as `04D8:0000` (Product ID left blank in MCC)
- [x] Unified Host programs and verifies the test application
- [ ] Test application runs after reset and power cycle: runs after programming; power cycle not yet recorded
- [ ] RAM trigger returns to bootloader
- [ ] Hardware switch trigger passes, when fitted
- [ ] ICSP recovery passes

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

Open items:

- Reserve the first 16 bytes of SRAM in the bootloader linker script, then run
  Test C (application requests the bootloader).
- Set USB Product ID `0x003C` in MCC.
- Rebuild the bootloader with `ICS_PGx2` before debugging it in MPLAB X (the
  image on the board has `ICS_PGx1`; programming is unaffected).
- Map a force-boot button (T1 or T2) in `bootloader_board.h` and run Test D.
- Record the power-cycle test (Test E) and ICSP recovery (Test F).
- Measure 3.3 V, VCAP, and the crystal frequency for the evidence list.
