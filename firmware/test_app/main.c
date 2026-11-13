/*
 * Bootloader-aware LED test application for the PIC32MX534F064H programmer PCB.
 *
 * Loaded over USB by the HID bootloader (Unified Host), linked with app_mx534.ld
 * so it lives at 0x9D008000 and above. It sets NO config bits: the bootloader
 * owns them (8 MHz crystal + PLL -> 80 MHz SYSCLK).
 *
 * Board (schematic, active-high LEDs through 4.7k, button pulled up):
 *   LED1 = RD4, LED2 = RD1, T2 = RB0 (pressed = low)
 *
 * Behaviour:
 *   - LED1 and LED2 alternate every 250 ms.
 *   - Press T2 at any time: the app asks the bootloader for update mode
 *     (writes the request pattern to the first 16 bytes of SRAM and does a
 *     software reset). The board then shows LED2 steady and appears on USB,
 *     ready for Unified Host. No RESET button needed.
 */

#include <xc.h>
#include <stdint.h>

#define SYSCLK_HZ        80000000UL
#define CORE_TIMER_HZ    (SYSCLK_HZ / 2UL)   /* core timer ticks at SYSCLK/2 */

#define LED1_MASK        (1U << 4)           /* RD4 */
#define LED2_MASK        (1U << 1)           /* RD1 */
#define T2_MASK          (1U << 0)           /* RB0 / AN0 */

/* Must match the bootloader (bootloader_board.h / Harmony bootloader). The
   linker script keeps the app's RAM above these 16 bytes. */
#define BTL_TRIGGER_RAM_ADDRESS   (0xA0000000UL)
#define BTL_TRIGGER_PATTERN       (0x5048434DUL)

#define BLINK_MS          250U
#define DEBOUNCE_MS       30U

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

static int t2_pressed(void)
{
    return (PORTB & T2_MASK) == 0U;
}

/* Ask the bootloader to stay in update mode, then reset. Does not return. */
static void request_bootloader_and_reset(void)
{
    volatile uint32_t * const ram = (volatile uint32_t *)BTL_TRIGGER_RAM_ADDRESS;

    (void)__builtin_disable_interrupts();

    ram[0] = BTL_TRIGGER_PATTERN;
    ram[1] = BTL_TRIGGER_PATTERN;
    ram[2] = BTL_TRIGGER_PATTERN;
    ram[3] = BTL_TRIGGER_PATTERN;
    __asm__ volatile ("sync" ::: "memory");

    /* PIC32 protected software-reset sequence. */
    SYSKEY = 0x00000000U;
    SYSKEY = 0xAA996655U;
    SYSKEY = 0x556699AAU;
    RSWRSTSET = _RSWRST_SWRST_MASK;
    (void)RSWRST;

    for (;;)
    {
        /* Wait for the reset to take effect. */
    }
}

int main(void)
{
    uint32_t ms_in_blink = 0U;
    uint32_t pressed_ms = 0U;

    /* RD1 and RD4 as digital outputs: LED1 on, LED2 off to start. */
    LATDCLR  = LED2_MASK;
    LATDSET  = LED1_MASK;
    TRISDCLR = LED1_MASK | LED2_MASK;

    /* T2 (RB0/AN0) as a digital input. The internal pull-up (CN2) keeps RB0
       high on boards with no button there, so it can't trigger by itself. */
    AD1PCFGSET = _AD1PCFG_PCFG0_MASK;
    TRISBSET   = T2_MASK;
    CNPUESET   = _CNPUE_CNPUE2_MASK;
    delay_ms(1U);

    /* If T2 is still held from entering/leaving the bootloader, wait for release. */
    while (t2_pressed())
    {
        delay_ms(1U);
    }

    for (;;)
    {
        delay_ms(1U);

        if (++ms_in_blink >= BLINK_MS)
        {
            ms_in_blink = 0U;
            LATDINV = LED1_MASK | LED2_MASK;
        }

        pressed_ms = t2_pressed() ? pressed_ms + 1U : 0U;
        if (pressed_ms >= DEBOUNCE_MS)
        {
            /* Visual cue: LED2 on, LED1 off, then hand over to the bootloader. */
            LATDCLR = LED1_MASK;
            LATDSET = LED2_MASK;
            request_bootloader_and_reset();
        }
    }
}
