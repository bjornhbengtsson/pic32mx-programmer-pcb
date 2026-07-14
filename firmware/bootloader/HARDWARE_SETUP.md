# Hardware setup: PCB, clamshell, PICkit 4, and MPLAB Snap

## 1. Insert the MCU correctly

The PIC32MX534F064H-I/PT is a 64-lead TQFP. Confirm:

- Socket body and contact pitch: 64-TQFP, 10 mm × 10 mm body, 0.50 mm pitch
- MCU pin 1 marker matches clamshell pin 1
- Clamshell adapter pin 1 matches PCB socket/header pin 1
- No bent leads or debris
- Lid is fully latched and applies even pressure

A 90-degree rotation can damage the MCU or board when power is applied.

## 2. Required MCU power connections

All supplies must be present:

- Every VDD pin to regulated 3.3 V
- Every VSS pin to ground
- AVDD to 3.3 V
- AVSS to ground
- VCAP to its required low-ESR capacitor to ground
- Decoupling capacitors close to each power pin pair

For this package, the important dedicated connections include:

| MCU pin | Signal |
|---:|---|
| 7 | MCLR |
| 15 | PGEC1 |
| 16 | PGED1 |
| 19 | AVDD |
| 20 | AVSS |
| 33 | USBID |
| 34 | VBUS |
| 35 | VUSB3V3 |
| 36 | USB D- |
| 37 | USB D+ |
| 39 | OSC1 |
| 40 | OSC2 |
| 56 | VCAP |
| 58 | C1RX/RF0 |
| 59 | C1TX/RF1 |

The CAN transceiver is unrelated to initial USB bootloader programming and can remain idle.

## 3. VCAP

VCAP is the internal regulator output. It is not another 3.3 V supply input.

Required:

```text
VCAP → low-ESR capacitor → GND
```

A typical value is 10 µF, subject to the exact device data sheet and capacitor ESR requirement.

Do not:

- connect VCAP directly to VDD
- power another circuit from VCAP
- omit the capacitor

## 4. MCLR

Recommended development connection:

```text
MCLR → 10 kΩ pull-up → 3.3 V
MCLR → programmer pin 1
```

Avoid a large capacitor directly on MCLR during programming. It can prevent the programmer from generating the required VPP/reset transition.

## 5. ICSP header mapping

### Standard six-signal mapping

| ICSP position | Signal | Connect to PIC32MX534F064H |
|---:|---|---|
| 1 | VPP / MCLR | MCU pin 7, MCLR |
| 2 | TVDD / target VDD sense | Board 3.3 V |
| 3 | VSS | Board ground |
| 4 | PGD / ICSPDAT | MCU pin 16, PGED1 |
| 5 | PGC / ICSPCLK | MCU pin 15, PGEC1 |
| 6 | AUX | Leave unconnected for normal ICSP |

The project configuration must use:

```c
#pragma config ICESEL = ICS_PGx1
```

### MPLAB Snap eight-pin connector

| Snap pin | Signal | Use |
|---:|---|---|
| 1 | TVPP/MCLR | MCLR |
| 2 | TVDD | 3.3 V sense |
| 3 | GND | Ground |
| 4 | PGD | PGED1 |
| 5 | PGC | PGEC1 |
| 6 | AUX | Normally NC |
| 7 | TDI | NC unless using JTAG |
| 8 | TMS | NC unless using JTAG |

### PICkit 4

Use its standard ICSP signals in the same order for the first six positions. Verify the triangle/pin-1 marking on the PICkit 4 cable or adapter.

## 6. ICSP loading rules

PGEC1 and PGED1 should be:

- short and directly routed
- free of capacitors
- free of LEDs
- free of pull-up or pull-down resistors
- free of series diodes
- disconnected from circuits that strongly drive the lines during programming

## 7. Powering the target

Preferred initial setup:

1. Disconnect USB from the PCB.
2. Power the PCB from a current-limited regulated 3.3 V supply.
3. Connect board ground to programmer ground.
4. Connect TVDD as a voltage-sense input.
5. Do not enable tool-supplied power.

Start with a conservative current limit, then raise it only after confirming no short or incorrect orientation.

Never allow the PICkit/Snap, USB input, and external supply to fight each other.

## 8. Pre-program electrical checks

With no MCU or with power removed:

- [ ] No short between 3.3 V and GND.
- [ ] ICSP pin 1 reaches MCLR.
- [ ] ICSP pin 4 reaches PGED1.
- [ ] ICSP pin 5 reaches PGEC1.
- [ ] Header pin 2 reaches 3.3 V.
- [ ] Header pin 3 reaches GND.
- [ ] D+ and D- are not swapped.
- [ ] VBUS reaches MCU VBUS sensing circuitry.
- [ ] VUSB3V3 is connected exactly as required by the data sheet.
- [ ] Crystal is connected to OSC1/OSC2 with the intended capacitors.
- [ ] VCAP is not shorted to VDD.

With power applied:

- [ ] 3.3 V is within the MCU operating range.
- [ ] VCAP rises to the expected internal-regulator level.
- [ ] MCLR idles high.
- [ ] Programmer reports a valid target voltage.

## 9. First connection sequence

1. Remove all power.
2. Insert MCU and latch clamshell.
3. Connect PICkit 4 or Snap to ICSP.
4. Connect external 3.3 V and ground.
5. Apply 3.3 V.
6. Open MPLAB IPE.
7. Device: `PIC32MX534F064H`.
8. Tool: PICkit 4 or Snap.
9. Click **Connect**.
10. Confirm the tool reads the correct device ID.
11. Perform a blank check before first programming.

The expected device ID family value for PIC32MX534F064H is `0x04400053`; MPLAB normally handles this automatically.
