/*
 * Minimal visible test application for the bootloader-aware application project.
 * Copy over the generated test application's src/app.c and map the LED macros in
 * test_app_board.h.
 */

#include "app.h"
#include "definitions.h"
#include "test_app_board.h"

#include <stdint.h>

APP_DATA appData;

void APP_Initialize(void)
{
    appData.state = APP_STATE_INIT;
    TEST_APP_LED_INITIALIZE();
}

void APP_Tasks(void)
{
    static uint32_t counter = 0U;

    switch (appData.state)
    {
        case APP_STATE_INIT:
            ++counter;
            if (counter >= TEST_APP_TOGGLE_ITERATIONS)
            {
                counter = 0U;
                TEST_APP_LED_TOGGLE();
            }
            break;

        default:
            counter = 0U;
            appData.state = APP_STATE_INIT;
            break;
    }
}
