# One-time ICSP programming with PICkit 4 or MPLAB Snap

A blank PIC32 cannot update itself over USB. The USB HID bootloader must first be loaded through ICSP.

## Method 1: MPLAB X IDE

1. Open `bootloader_pic32mx534.X`.
2. Open **Project Properties**.
3. Confirm:
   - Device: `PIC32MX534F064H`
   - Compiler: XC32
   - Hardware tool: PICkit 4 or Snap
4. Confirm the board is externally powered at 3.3 V.
5. Confirm tool power is disabled.
6. Select **Clean and Build Project**.
7. Select **Make and Program Device**.
8. Review the output window for:
   - device detected
   - erase complete
   - programming complete
   - verification complete

Do not use the test application's normal linker project for this step.

## Method 2: MPLAB IPE GUI

1. Open MPLAB IPE.
2. Device: `PIC32MX534F064H`.
3. Tool: PICkit 4 or Snap.
4. Click **Connect**.
5. Confirm target voltage.
6. Browse to:

```text
bootloader_pic32mx534.X/
  dist/default/production/
    bootloader_pic32mx534.X.production.hex
```

7. Click **Erase**.
8. Click **Blank Check**.
9. Click **Program**.
10. Confirm **Programming/Verify complete**.
11. Read back the device where permitted and save the IPE log.

## Method 3: IPECMD PowerShell script

The included script locates `ipecmd.exe` under a normal MPLAB X installation.

PICkit 4:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\program_bootloader.ps1 `
  -Tool PICkit4 `
  -Hex generated_projects\bootloader_pic32mx534.X\dist\default\production\bootloader_pic32mx534.X.production.hex
```

Snap:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\program_bootloader.ps1 `
  -Tool Snap `
  -Hex generated_projects\bootloader_pic32mx534.X\dist\default\production\bootloader_pic32mx534.X.production.hex
```

The script uses:

```text
-TPPK4   for PICkit 4
-TPSNAP  for MPLAB Snap
-P32MX534F064H
-E       erase
-M       program
-Y       verify
-OL      release from reset after operation
```

Run the installed `ipecmd.exe -?` and inspect MPLAB X's local **Readme for IPECMD** if a newer IPE version changes an option.

## Troubleshooting MPLAB IPE with the Snap

Seen on MPLAB IPE v6.30 with the Snap on 2026-11-13:

- **`You have entered an invalid value (null) for the Voltage Level on the Snap
  Power property page`, then `Connection Failed`.** The Snap cannot power a
  target, so its Power page has no voltage box, but IPE still checks a stored
  value. Try **Power → Reset to defaults**, then Connect. If the GUI still
  refuses, use the command line, which ignores this setting:
  `ipecmd.exe -TPSNAP -P32MX534F064H -I` reads the device ID. On the first
  command-line connection IPE may update the Snap firmware (02.04.10 →
  02.04.55); let it finish.
- **`Erase Target Failed` / `Programming Target Failed` from `ipecmd` while the
  IPE window is open.** The GUI holds the Snap. Close IPE, or use only the GUI.
- **`*** Hold In Reset mode is enabled ***` after programming.** The Snap is
  holding MCLR low, so nothing runs and USB will not enumerate. Click
  **Disconnect** (or Settings → Release from Reset) before testing USB.
- A device ID shown as `0x4400000` with revision `0xA2` is normal for this part;
  IPE masks the revision bits.

## Programmer power

The script intentionally does not request target power. The PCB should be powered from a regulated 3.3 V source, and TVDD should be used for voltage sensing.

Do not add a target-power option while USB or another power source is connected.

## First boot after ICSP programming

1. Disconnect the programmer or leave it connected without holding reset.
2. Keep the board powered.
3. Connect the board's USB device connector to the PC.
4. With no valid application in `0x9D008000`, `run_Application()` returns and the bootloader remains active.
5. Windows should enumerate a HID device with VID/PID `04D8:003C`.

HID does not require a custom Windows kernel driver.

## Recovering a board

PICkit 4 or Snap remains the recovery path even after the USB bootloader is installed.

Use ICSP recovery when:

- the bootloader region was corrupted
- configuration bits were changed incorrectly
- USB clocking no longer works
- an application repeatedly resets before bootloader entry
- the USB descriptor no longer matches Unified Host
- the application linker overwrote the bootloader
