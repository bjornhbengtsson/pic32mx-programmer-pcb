# Using the bootloader on your own board

Chips prepared by the lab ([Part 1](../lab-tech-guide/README.md)) contain the
USB bootloader, and possibly the LED test app (ask which: the lab can load
chips either way). When you solder one onto **your own** board,
the bootloader only works if your board gives it what it expects. Check your
schematic against this list **before** you order the PCB.

Pin numbers are for the 64-pin TQFP PIC32MX534F064H. The programmer board's
schematic (`hardware/schematic/`) is a working reference for every item.

## Must have (or the bootloader won't run or won't show up on USB)

| # | Requirement | Pins | Why |
|---|---|---|---|
| 1 | **8 MHz crystal** between OSC1 and OSC2, with load capacitors to GND (22 pF on the reference board) | OSC1 = 39, OSC2 = 40 | The bootloader is built for an 8 MHz crystal (HS mode, PLL to 80 MHz and 48 MHz for USB). Any other frequency, or no crystal, and **USB will not work**. |
| 2 | 3.3 V on **every** VDD pin and AVDD; GND on every VSS and AVSS; 100 nF decoupling at each VDD pin | VDD 10, 26, 38, 57; AVDD 19; VSS 9, 25, 41; AVSS 20 | Basic power. |
| 3 | **VCAP** to a 10 µF low-ESR capacitor to GND. Nothing else on this pin. | 56 | Core regulator. Without it the chip won't run. Never connect it to 3.3 V. |
| 4 | **MCLR** pulled up to 3.3 V (10 kΩ) | 7 | Otherwise the chip stays in reset. |
| 5 | **USB:** D+ and D− to the USB connector (27 Ω series resistors on the reference board), **VBUS** to the connector's 5 V, **VUSB3V3** to 3.3 V | D+ 37, D− 36, VBUS 34, VUSB3V3 35 | The bootloader is a USB device. VBUS must see 5 V or it won't connect. |

## Strongly recommended

| # | Requirement | Pins | Why |
|---|---|---|---|
| 6 | **Update button:** push-button from RB0 to GND, with a 4.7–10 kΩ pull-up to 3.3 V | RB0 = 16 | Hold it while resetting to get back into update mode. **Without it, once you load an app you can only get back into update mode from your own app (item 9) or with a Snap/PICkit.** |
| 7 | A reset button from MCLR to GND | 7 | So "hold button + tap reset" works without unplugging. |
| 8 | **ICSP header** in the Snap/PICkit order: 1 MCLR, 2 3.3 V, 3 GND, 4 PGED2, 5 PGEC2 | PGED2 = 18 (RB7), PGEC2 = 17 (RB6) | Lets a lab tech recover the chip if the bootloader is ever damaged, and lets you debug in MPLAB X. The bootloader is built for the **PGEC2/PGED2** pair. |

## If your chip came with the LED app

Some batches are loaded with the LED test app so they blink as soon as they're
soldered. Then:

- The chip **starts the LED app**, not update mode. It toggles **RD4 (pin 52)
  and RD1 (pin 49)** every 250 ms. Put LEDs there (to GND through a resistor)
  to see it, and make sure nothing else on your board is connected to those pins.
- To load **your** code over USB you **need the RB0 update button** (item 6):
  hold it, tap reset, and the chip goes into update mode. Without it, ask a lab
  tech to reload the chip with a Snap.
- Once you've loaded your own app, the LED app is gone.

## Things the bootloader does to your pins

While the bootloader is running (update mode):

- **RD1 (pin 49) is driven HIGH** to light the status LED. Put an LED (to GND
  through a resistor) here if you like, or leave it unconnected. **Don't**
  connect anything to RD1 that would be harmed by 3.3 V, or that drives it.
- **RB0 (pin 16)** is read as a digital input at reset.
- USB D+/D− are used.

All other pins are left in their reset state (inputs). Your app reconfigures
everything once it starts.

## Your app

1. Start from [`firmware/test_app`](../../firmware/test_app/). Keep its linker
   script and the "no `#pragma config`" rule ([Task 3](README.md#task-3-write-and-build-your-own-app)).
2. Change the LED pins in `main.c` to wherever **your** board's LEDs are.
3. Load it over USB as in [Task 2](README.md#task-2-put-new-firmware-on-the-board),
   using **your** board's USB connector and update button.

### Going back to update mode from your app (no button needed)

Your app can ask for update mode itself, for example when it receives a command
over UART: call `Bootloader_RequestAndReset()` from
[`firmware/bootloader/test_app_snippets/bootloader_request.c`](../../firmware/bootloader/test_app_snippets/bootloader_request.c).
It writes a 4-word pattern to the first 16 bytes of RAM and resets; the
bootloader sees it and stays in update mode.

The test app in [`firmware/test_app/main.c`](../../firmware/test_app/main.c)
already does this when T2 (RB0) is pressed: copy its
`request_bootloader_and_reset()` function. Tested on hardware 2026-11-13.

## Quick check after assembly

1. Plug your board's USB into a PC. With a fresh chip (bootloader only), Windows
   should show a new **USB Input Device** (`VID_04D8&PID_003C`) and RD1 goes high.
2. If not: measure 3.3 V on VDD, check the crystal is 8 MHz and both load caps
   are fitted, check VCAP's capacitor, check MCLR is high, check D+/D− aren't
   swapped and VBUS gets 5 V.
