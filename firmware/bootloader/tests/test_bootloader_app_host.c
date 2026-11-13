#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "app.h"
#include "xc.h"

uint32_t test_trigger_ram[4] = {0U, 0U, 0U, 0U};

/* Mock registers (see mocks/xc.h). T2 on RB0 starts released (pulled high). */
volatile uint32_t AD1PCFGSET = 0U;
volatile uint32_t TRISBSET = 0U;
volatile uint32_t PORTB = _PORTB_RB0_MASK;
volatile uint32_t LATDSET = 0U;
volatile uint32_t LATDCLR = 0U;
volatile uint32_t TRISDCLR = 0U;

bool bootloader_Trigger(void);

int main(void)
{
    APP_Initialize();
    /* Status LED (LED2, RD1) is configured as an output and driven on. */
    assert(TRISDCLR == _LATD_LATD1_MASK);
    APP_Tasks();
    assert(LATDSET == _LATD_LATD1_MASK);

    assert(bootloader_Trigger() == false);
    /* T2 pin (RB0/AN0) is switched to a digital input before it is read. */
    assert(AD1PCFGSET == _AD1PCFG_PCFG0_MASK);
    assert(TRISBSET == _PORTB_RB0_MASK);

    /* T2 held (RB0 pulled low) forces the bootloader. */
    PORTB = 0U;
    assert(bootloader_Trigger() == true);
    PORTB = _PORTB_RB0_MASK;
    assert(bootloader_Trigger() == false);

    for (unsigned int i = 0U; i < 4U; ++i)
    {
        test_trigger_ram[i] = 0x5048434DUL;
    }

    assert(bootloader_Trigger() == true);

    for (unsigned int i = 0U; i < 4U; ++i)
    {
        assert(test_trigger_ram[i] == 0U);
    }

    assert(bootloader_Trigger() == false);

    test_trigger_ram[0] = 0x5048434DUL;
    test_trigger_ram[1] = 0x5048434DUL;
    test_trigger_ram[2] = 0x5048434DUL;
    test_trigger_ram[3] = 0x00000000UL;

    assert(bootloader_Trigger() == false);

    puts("PASS: bootloader trigger host test");
    return 0;
}
