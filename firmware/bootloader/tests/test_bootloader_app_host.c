#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "app.h"

uint32_t test_trigger_ram[4] = {0U, 0U, 0U, 0U};

bool bootloader_Trigger(void);

int main(void)
{
    APP_Initialize();
    APP_Tasks();

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
