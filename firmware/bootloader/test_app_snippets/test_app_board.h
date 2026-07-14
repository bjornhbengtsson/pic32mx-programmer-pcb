#ifndef PIC32MX534_TEST_APP_BOARD_H
#define PIC32MX534_TEST_APP_BOARD_H

/*
 * Replace these defaults with MCC-generated pin aliases.
 *
 * Active-high example:
 *   #define TEST_APP_LED_INITIALIZE() APP_LED_Clear()
 *   #define TEST_APP_LED_TOGGLE()     APP_LED_Toggle()
 */
#ifndef TEST_APP_LED_INITIALIZE
#define TEST_APP_LED_INITIALIZE() ((void)0)
#endif

#ifndef TEST_APP_LED_TOGGLE
#define TEST_APP_LED_TOGGLE()     ((void)0)
#endif

#ifndef TEST_APP_TOGGLE_ITERATIONS
#define TEST_APP_TOGGLE_ITERATIONS 1000000UL
#endif

#endif
