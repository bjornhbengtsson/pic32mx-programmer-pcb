#ifndef TEST_MOCK_XC_H
#define TEST_MOCK_XC_H

/* Host-side stand-ins for the PIC32 registers used by bootloader_board.h.
   The real SET/CLR registers are write-only strobes; here they just record
   the last value written so the test can check them. */

#include <stdint.h>

extern volatile uint32_t AD1PCFGSET;
extern volatile uint32_t TRISBSET;
extern volatile uint32_t PORTB;
extern volatile uint32_t LATDSET;
extern volatile uint32_t LATDCLR;
extern volatile uint32_t TRISDCLR;

#define _AD1PCFG_PCFG0_MASK  0x00000001U
#define _PORTB_RB0_MASK      0x00000001U
#define _LATD_LATD1_MASK     0x00000002U

#endif
