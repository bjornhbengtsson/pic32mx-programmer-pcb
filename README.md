# PIC32MX 64-Pin Programmer PCB

A reusable socketed programmer, USB bootloader, firmware flashing, and hardware-validation platform for 64-pin PIC32MX microcontrollers.

<img width="1319" height="1086" alt="Programmer_Board_Product" src="https://github.com/user-attachments/assets/554a9d73-2a42-4f53-bddf-0b3701278511" />

## Overview

This project provides a development and test platform for PIC32MX 64-pin MCUs without requiring the microcontroller to be permanently soldered to a target PCB. A clamshell test socket allows an MCU to be inserted, powered, programmed, tested, removed, and reused.

The project was developed as an educational and research-oriented PCB platform using Altium Designer. The board is intended for firmware development, classroom instruction, early hardware validation, and low-volume embedded-system development.

## Target Device

- **Initial MCU:** Microchip PIC32MX534F064H-I/PT
- **Package:** 64-pin TQFP
- **Architecture:** 32-bit PIC32MX
- **Programming tools:** MPLAB PICkit 4 and MPLAB Snap

> Compatibility with other 64-pin PIC32MX devices must be verified against their package pinout, power requirements, and peripheral mappings. Contact me if you would like to commission a version adapted for a different MCU. bjorn.h.bengtsson@gmail.com

## Main Features

- 64-pin clamshell test socket
- ICSP programming and debugging
- USB bootloader support
- USB D+, D-, VBUS, and USB-ID connections
- MCLR/reset circuitry
- VCAP, oscillator, decoupling, and power-support circuitry
- CAN communication interface
- MikroBUS expansion socket
- Status LEDs and pushbuttons
- Peripheral breakout headers
- Power, ground, and signal test points

## ICSP Interface

The ICSP interface exposes:

- MCLR
- PGEC
- PGED
- VCC
- GND

## Repository Structure

```text
pic32mx-programmer-pcb/
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── docs/
│   ├── PIC32MX_Programmer_PCB_Poster.pdf
│   ├── PIC32MX_Project_Notes.pdf
│   └── README.md
├── firmware/
│   ├── bootloader/
│   └── README.md
├── hardware/
│   ├── altium/
│   ├── assembly/
│   ├── bom/
│   ├── gerbers/
│   ├── schematic/
│   ├── step/
│   └── README.md
└── images/

## Development Process

1. Learn Altium Designer
2. Create the schematic
3. Select and verify components
4. Complete the PCB layout
5. Apply manufacturing design rules
6. Generate fabrication and assembly files
7. Assemble the PCB
8. Perform electrical bring-up
9. Flash and validate firmware
10. Test USB bootloading and peripheral functions

## Design Challenges

- Mapping the MCU's 64 pins to the clamshell socket
- Routing the USB differential pair
- Maintaining mechanical clearance around the socket and headers
- Applying signal-integrity-aware routing
- Reducing Altium DRC violations
- Meeting PCB fabrication constraints
- Planning repeatable firmware and hardware validation

## Validation Status

### Completed

- Manufactured and assembled the PCB
- Inspected the power rails for shorts
- Verified the regulated supply voltages
- Successfully powered the assembled board

### Remaining

- Confirm MCLR behavior
- Detect the MCU with MPLAB
- Program a basic LED test
- Validate oscillator operation
- Validate USB enumeration
- Flash firmware through the USB bootloader
- Test CAN communication
- Test MikroBUS and breakout connections

## Manufacturing

The PCB was manufactured by JLCPCB and hand assembled.,

The design is also intended for SMT assembly using the ASU Polytechnic manufacturing line. Gerber and drill outputs, a BOM, assembly drawings, a schematic PDF, and a STEP model are included. Placement files and test documentation will be added as the project is finalized.

## Project Status

Current stage: PCB manufactured, assembled, and successfully powered.

Basic power validation has been completed. The next step is to establish ICSP communication with the PIC32MX534F064H and program an initial test application using MPLAB X or MPLAB IPE.

## Author

**Bjorn Bengtsson**  
Electrical Engineering Student  
Arizona State University

- GitHub: [bjornhbengtsson](https://github.com/bjornhbengtsson)
- LinkedIn: [Bjorn Bengtsson](https://www.linkedin.com/in/bjorn-bengtsson-love/)

## Acknowledgments

Special thanks to John T. Lewis, Billal Abulfotuh, and Brad Bengtsson for their support and guidance.

## Custom Hardware Inquiries

Contact me if you would like to commission a version of this programmer adapted for a different MCU, package, pinout, programming interface, or set of peripherals.
- Contact: bjorn.h.bengtsson@gmail.com

## License

This repository is provided under the MIT License unless otherwise noted. Third-party component models, manufacturer documentation, and proprietary Altium libraries remain subject to their original licenses.
