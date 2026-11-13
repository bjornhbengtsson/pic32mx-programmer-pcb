/*
 * Bootloader-aware LED test application for the PIC32MX534F064H programmer PCB.
 *
 * Loaded over USB by the HID bootloader (Unified Host), linked with app_mx534.ld
 * so it lives at 0x9D008000 and above. It sets NO config bits: the bootloader
 * owns them (8 MHz crystal + PLL -> 80 MHz SYSCLK).
 *
 * Board LEDs (schematic, active-high through 4.7k):
 *   LED1 = RD4, LED2 = RD1
 * Behaviour: LED1 and LED2 alternate every 250 ms.
 */

#include <xc.h>
#include <stdint.h>

#define SYSCLK_HZ        80000000UL
#define CORE_TIMER_HZ    (SYSCLK_HZ / 2UL)   /* core timer ticks at SYSCLK/2 */

#define LED1_MASK        (1U << 4)           /* RD4 */
#define LED2_MASK        (1U << 1)           /* RD1 */

static void delay_ms(uint32_t ms)
{
    const uint32_t ticks_per_ms = CORE_TIMER_HZ / 1000UL;
    while (ms-- > 0U)
    {
        uint32_t start = _CP0_GET_COUNT();
        while ((uint32_t)(_CP0_GET_COUNT() - start) < ticks_per_ms)
        {
        }
    }
}

int main(void)
{
    /* RD1 and RD4 as digital outputs: LED1 on, LED2 off to start. */
    LATDCLR  = LED2_MASK;
    LATDSET  = LED1_MASK;
    TRISDCLR = LED1_MASK | LED2_MASK;

    for (;;)
    {
        delay_ms(250U);
        LATDINV = LED1_MASK | LED2_MASK;
    }
}
