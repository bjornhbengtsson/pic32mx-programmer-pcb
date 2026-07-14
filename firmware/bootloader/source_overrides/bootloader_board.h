#ifndef PIC32MX534_BOOTLOADER_BOARD_H
#define PIC32MX534_BOOTLOADER_BOARD_H

#include <stdbool.h>

/*
 * Set these to 1 only after mapping the actual board pins in MCC.
 * Defaults let the bootloader operate with:
 *   - no hardware force switch
 *   - no status LED
 *   - RAM request trigger
 *   - automatic bootloader stay when application Flash is blank
 */
#define BOARD_BOOT_SWITCH_ENABLED       0
#define BOARD_STATUS_LED_ENABLED        0

/*
 * Example active-low switch mapping after MCC creates BOOT_SW_Get():
 *
 * #undef BOARD_BOOT_SWITCH_ENABLED
 * #define BOARD_BOOT_SWITCH_ENABLED 1
 * #define BOARD_BOOT_SWITCH_IS_PRESSED() (BOOT_SW_Get() == 0U)
 *
 * Example active-high LED mapping after MCC creates BTL_LED_Set/Clear():
 *
 * #undef BOARD_STATUS_LED_ENABLED
 * #define BOARD_STATUS_LED_ENABLED 1
 * #define BOARD_STATUS_LED_INITIALIZE() BTL_LED_Clear()
 * #define BOARD_STATUS_LED_ON()         BTL_LED_Set()
 * #define BOARD_STATUS_LED_OFF()        BTL_LED_Clear()
 */

#ifndef BOARD_BOOT_SWITCH_IS_PRESSED
#define BOARD_BOOT_SWITCH_IS_PRESSED()  (false)
#endif

#ifndef BOARD_STATUS_LED_INITIALIZE
#define BOARD_STATUS_LED_INITIALIZE()   ((void)0)
#endif

#ifndef BOARD_STATUS_LED_ON
#define BOARD_STATUS_LED_ON()           ((void)0)
#endif

#ifndef BOARD_STATUS_LED_OFF
#define BOARD_STATUS_LED_OFF()          ((void)0)
#endif

/* Gives switch contacts and supply rails time to settle after reset. */
#ifndef BOOTLOADER_TRIGGER_STARTUP_DELAY_CYCLES
#define BOOTLOADER_TRIGGER_STARTUP_DELAY_CYCLES 2000UL
#endif

#endif
