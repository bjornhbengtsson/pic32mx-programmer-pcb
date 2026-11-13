# Hardware Files

This directory contains the editable PCB design sources and generated manufacturing outputs.

## Directory Structure

- `altium/` — Editable Altium project, schematic, PCB, and library files
- `assembly/` — Assembly drawings
- `bom/` — Bill of materials
- `gerbers/` — Gerber and NC drill fabrication files
- `schematic/` — Exported schematic PDF
- `step/` — Exported board-level STEP model

Generated manufacturing files should be regenerated from the approved Altium design rather than edited manually.

## Known issues (rev PCB-BL-2)

- **T1 is not connected to the MCU.** The `RB4/T1` net label is not joined to
  the T1 switch net. In the netlist, T1, R1, R15 and MCP2561 pin 5 (SPLIT) are
  on one net, and MCU pin 12 (RB4) is alone. Holding T1 has no effect on the
  firmware, and pressing it grounds the CAN transceiver's SPLIT pin. Found
  2026-11-13 and **confirmed with a continuity meter**: T2 pad → MCU pin 16
  beeps; T1 pad → MCU pin 12 is open. Workaround: the bootloader's update
  button is **T2** (RB0). Fix the net label in the next revision (and check
  why T1's net joins R15 / MCP2561 SPLIT).
- **ICSP uses PGEC2/PGED2.** The Programmer Port (J2) is wired to RB6/RB7
  (pins 17/18). Firmware must use `ICESEL = ICS_PGx2` for debugging.
