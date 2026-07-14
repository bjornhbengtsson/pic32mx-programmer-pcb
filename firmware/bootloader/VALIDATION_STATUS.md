# Validation status

## What was checked before delivery

- The memory map was derived from the target's 64 KiB Program Flash and 16 KiB SRAM.
- The 32 KiB bootloader reservation follows Microchip's PIC32MX USB HID example.
- The application reset page and EBASE split follows Microchip's generated PIC32MX application linker:
  - application jump/reset page at `0x9D008000`
  - EBASE/code at `0x9D009000`
- The first 16 SRAM bytes are reserved for the standard `0x5048434D` boot request.
- The ICSP mapping uses PGEC1/PGED1 and matches `ICESEL = ICS_PGx1`.
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

- [ ] Bootloader project generated for exact device
- [ ] Bootloader XC32 production build passes
- [ ] Test application XC32 production build passes
- [ ] Static project verification passes
- [ ] Both HEX layout checks pass
- [ ] PICkit 4 program/verify passes
- [ ] Snap program/verify passes, when Snap support is required
- [ ] USB HID enumerates as `04D8:003C`
- [ ] Unified Host programs and verifies the test application
- [ ] Test application runs after reset and power cycle
- [ ] RAM trigger returns to bootloader
- [ ] Hardware switch trigger passes, when fitted
- [ ] ICSP recovery passes
