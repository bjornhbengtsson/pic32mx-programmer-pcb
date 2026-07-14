#include "bootloader_request.h"
#include "definitions.h"

#include <stdint.h>

#define BTL_TRIGGER_PATTERN       (0x5048434DUL)
#define BTL_TRIGGER_RAM_ADDRESS   (0xA0000000UL)

void Bootloader_RequestAndReset(void)
{
    volatile uint32_t * const ram =
        (volatile uint32_t *)(uintptr_t)BTL_TRIGGER_RAM_ADDRESS;

    ram[0] = BTL_TRIGGER_PATTERN;
    ram[1] = BTL_TRIGGER_PATTERN;
    ram[2] = BTL_TRIGGER_PATTERN;
    ram[3] = BTL_TRIGGER_PATTERN;

#if defined(__mips__)
    __asm__ volatile ("sync" ::: "memory");
#endif

    (void)__builtin_disable_interrupts();

    /* PIC32 protected software-reset sequence. */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;
    RSWRSTSET = _RSWRST_SWRST_MASK;
    (void)RSWRST;

    for (;;)
    {
        /* Wait for reset. */
    }
}
