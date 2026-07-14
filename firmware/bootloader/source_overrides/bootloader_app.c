/*
 * Board-specific application layer for the Harmony 3 USB HID bootloader.
 *
 * Copy this file over the MCC-generated bootloader project's src/app.c.
 * Keep the generated app.h and all generated Harmony bootloader sources.
 */

#include "app.h"
#include "definitions.h"
#include "bootloader_board.h"

#include <stdbool.h>
#include <stdint.h>

#define BTL_TRIGGER_PATTERN  (0x5048434DUL)

APP_DATA appData;

static volatile uint32_t * const triggerWords =
    (volatile uint32_t *)(uintptr_t)BTL_TRIGGER_RAM_START;

static void bootloader_MemoryBarrier(void)
{
#if defined(__mips__)
    __asm__ volatile ("sync" ::: "memory");
#else
    __asm__ volatile ("" ::: "memory");
#endif
}

static bool bootloader_RamRequestPresent(void)
{
    bool present =
        (triggerWords[0] == BTL_TRIGGER_PATTERN) &&
        (triggerWords[1] == BTL_TRIGGER_PATTERN) &&
        (triggerWords[2] == BTL_TRIGGER_PATTERN) &&
        (triggerWords[3] == BTL_TRIGGER_PATTERN);

    if (present)
    {
        /* Clear all four words so the request is one-shot. */
        triggerWords[0] = 0U;
        triggerWords[1] = 0U;
        triggerWords[2] = 0U;
        triggerWords[3] = 0U;
        bootloader_MemoryBarrier();
    }

    return present;
}

/*
 * Strong definition overrides Harmony's weak bootloader_Trigger().
 * It is called before the bootloader decides whether to jump to the app.
 */
bool bootloader_Trigger(void)
{
    volatile uint32_t delay;

    for (delay = 0U;
         delay < BOOTLOADER_TRIGGER_STARTUP_DELAY_CYCLES;
         ++delay)
    {
        __asm__ volatile ("nop");
    }

    if (bootloader_RamRequestPresent())
    {
        return true;
    }

#if BOARD_BOOT_SWITCH_ENABLED
    if (BOARD_BOOT_SWITCH_IS_PRESSED())
    {
        return true;
    }
#endif

    return false;
}

void APP_Initialize(void)
{
    appData.state = APP_STATE_INIT;
    BOARD_STATUS_LED_INITIALIZE();
}

void APP_Tasks(void)
{
    switch (appData.state)
    {
        case APP_STATE_INIT:
            BOARD_STATUS_LED_ON();
            break;

        default:
            BOARD_STATUS_LED_OFF();
            appData.state = APP_STATE_INIT;
            break;
    }
}
