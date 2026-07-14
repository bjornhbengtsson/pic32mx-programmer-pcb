# USB firmware update and validation

## 1. Prepare the test application

Build the bootloader-aware test application but do not program it with PICkit/Snap.

Production HEX location:

```text
generated_projects/test_app_pic32mx534.X/
  dist/default/production/
    test_app_pic32mx534.X.production.hex
```

Run the layout checker first:

```powershell
python scripts\hex_layout.py `
  --mode application `
  generated_projects\test_app_pic32mx534.X\dist\default\production\test_app_pic32mx534.X.production.hex
```

Proceed only when it reports `PASS`.

## 2. Start the USB bootloader

Any of these conditions should keep the bootloader active:

- no valid application exists at `0x9D008000`
- the optional force-boot switch is held during reset
- the application writes four copies of `0x5048434D` to the first 16 SRAM bytes, then performs a software reset

For first use, Program Flash after the bootloader should be blank, so no switch is required.

## 3. Open Microchip Unified Host

Typical location in a Harmony 3 installation:

```text
<harmony3_path>\bootloader\tools\UnifiedHost-*\UnifiedHost-*.jar
```

Launch example:

```powershell
java -jar C:\microchip\harmony\v3\bootloader\tools\UnifiedHost-1.20.0\UnifiedHost-1.20.0.jar
```

The actual versioned directory may differ.

Configure:

```text
Architecture: PIC32
Protocol: USB
Product ID: 3C
```

Select the enumerated USB HID bootloader.

## 4. Program the application

1. Load the test application's production HEX.
2. Open the Unified Host console.
3. Click **Program Device**.
4. Wait for erase, write, and verify to complete.
5. Allow the host to reset the board or manually reset it.
6. Confirm the application LED blinks.

Close Unified Host before trying to program the MCU through MPLAB X/IPE again, because both tools may contend for the device.

## 5. Validate all entry paths

### Test A: Blank application

1. Erase/program only the bootloader through ICSP.
2. Connect USB.
3. Confirm HID enumeration.
4. Result: pass when Unified Host detects Product ID `3C`.

### Test B: USB programming

1. Load the test application through Unified Host.
2. Reset.
3. Confirm the test LED blinks.
4. Result: proves receive, erase, write, verify, reset, and jump.

### Test C: Application software request

1. Call `Bootloader_RequestAndReset()` from the running application.
2. Confirm the LED stops blinking and HID bootloader re-enumerates.
3. Program again.
4. Result: proves the 16-byte RAM trigger and software reset.

### Test D: Hardware force switch

Applicable only after mapping the switch in `bootloader_board.h`.

1. Hold the switch.
2. Reset or power-cycle.
3. Confirm bootloader enumeration rather than application execution.
4. Release the switch before the next reset.

### Test E: Power-cycle persistence

1. Load the application.
2. Remove all power.
3. Reapply power without holding force boot.
4. Confirm the application starts.

### Test F: ICSP recovery

1. Intentionally load a harmless application image that does not request bootloader mode.
2. Reprogram the bootloader through ICSP.
3. Confirm USB bootloader enumeration returns.

## 6. Record objective evidence

Save:

- MPLAB X build log
- bootloader `.map`
- test application `.map`
- `verify_project.py` output
- both `hex_layout.py` outputs
- MPLAB IPE programming log
- Unified Host console log
- USB VID/PID screenshot
- measured 3.3 V, VCAP, and crystal frequency
- LED behavior video or test notes
- MCU lot/revision and socket cycle count

## 7. Acceptance criteria

| Test | Required result |
|---|---|
| ICSP device detection | Correct PIC32MX534F064H |
| ICSP program/verify | Pass |
| USB enumeration | HID, VID `04D8`, PID `003C` |
| Bootloader HEX boundary | No PFM data at or above `0x1D008000` |
| Application HEX boundary | No PFM data below `0x1D008000`; no Boot Flash/config data |
| USB program | Erase/write/verify pass |
| App start | Test LED blinks |
| RAM trigger | Returns to bootloader |
| Force switch | Returns to bootloader, when fitted |
| Power cycle | Application restarts |
| ICSP recovery | Pass |

## 8. Failure isolation

### Programmer cannot detect device

Check MCLR, TVDD, ground, PGEC1/PGED1 mapping, socket orientation, VCAP, and all power pins.

### Programmer detects wrong/unstable voltage

Check external 3.3 V supply, common ground, TVDD wiring, current limit, and power-source contention.

### Bootloader programs but USB does not enumerate

Check:

- 8 MHz oscillator actually starts
- PLL/configuration bits
- 48 MHz USB clock
- VBUS input
- VUSB3V3 connection
- D+/D- polarity
- USB connector orientation
- ESD/filter parts
- ground plane and differential routing
- VID/PID descriptor
- Windows Device Manager hardware ID

### Application upload succeeds but does not run

Check:

- application linker reset at `0xBD008000`
- EBASE at `0x9D009000`
- application HEX contains data at physical `0x1D008000`
- no config words in application HEX
- application clock assumptions match bootloader configuration
- test LED mapping and polarity

### Application overwrites bootloader

Stop using that HEX. Fix the application linker and verify it with `hex_layout.py` before another USB update.
