#ifndef PIC32MX534_BOOTLOADER_BOARD_H
#define PIC32MX534_BOOTLOADER_BOARD_H

/*
 * Board mapping for the PIC32MX534F064H programmer PCB (schematic
 * "EEE314 PIC32540 Programmer").
 *
 *   T2 (force-boot button) : RB0 / AN0 / PGED1, MCU pin 16, R2 4.7 kohm pull-up, pressed = LOW
 *   T1                     : NOT usable. In the schematic netlist the T1 switch is on a
 *                            net with R1, R15 and the MCP2561 SPLIT pin; the "RB4/T1"
 *                            label is not joined to it, so RB4 (pin 12) floats.
 *                            Confirmed on hardware 2026-11-13: holding T1 had no effect.
 *   T3 (RESET button)      : MCLR, MCU pin 7
 *   LED2 (status LED)      : RD1, MCU pin 49, active-high
 *
 * Behaviour:
 *   - Hold T2 while the board resets (tap T3, or plug in USB) -> bootloader.
 *   - The application can also request the bootloader by writing the
 *     0x5048434D pattern to the first 16 bytes of SRAM and resetting.
 *   - If the application area is blank, the bootloader always stays.
 *   - While the bootloader is running, LED2 is on steadily.
 *
 * Registers are used directly so this file does not depend on MCC pin names.
 */

#include <xc.h>
#include <stdbool.h>
#include <stdint.h>

/* First 16 bytes of SRAM hold the application's boot request. The bootloader
   and application linker scripts must both start their RAM at 0xA0000010. */
#ifndef BTL_TRIGGER_RAM_START
#define BTL_TRIGGER_RAM_START           (0xA0000000UL)
#endif

/* ---- Force-boot switch: T2 on RB0 ------------------------------------- */
#define BOARD_BOOT_SWITCH_ENABLED       1

/* RB0 is AN0 and powers up as an analog input, which always reads 0.
   Make it a digital input before reading it. (RB0 is also PGED1, which is
   free because ICSP on this board uses PGEC2/PGED2.) */
#define BOARD_BOOT_SWITCH_INITIALIZE()                                   \
    do {                                                                 \
        AD1PCFGSET = _AD1PCFG_PCFG0_MASK;  /* RB0 digital */            \
        TRISBSET   = _PORTB_RB0_MASK;      /* RB0 input   */            \
    } while (0)

#define BOARD_BOOT_SWITCH_IS_PRESSED()  ((PORTB & _PORTB_RB0_MASK) == 0U)

/* ---- Status LED: LED2 on RD1 ------------------------------------------ */
#define BOARD_STATUS_LED_ENABLED        1

#define BOARD_STATUS_LED_INITIALIZE()                                    \
    do {                                                                 \
        LATDCLR  = _LATD_LATD1_MASK;                                     \
        TRISDCLR = _LATD_LATD1_MASK;                                     \
    } while (0)
#define BOARD_STATUS_LED_ON()           (LATDSET = _LATD_LATD1_MASK)
#define BOARD_STATUS_LED_OFF()          (LATDCLR = _LATD_LATD1_MASK)

/* Gives the switch input and supply rails time to settle after reset. */
#ifndef BOOTLOADER_TRIGGER_STARTUP_DELAY_CYCLES
#define BOOTLOADER_TRIGGER_STARTUP_DELAY_CYCLES 2000UL
#endif

#endif
