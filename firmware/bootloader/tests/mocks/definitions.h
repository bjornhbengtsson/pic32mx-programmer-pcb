#ifndef TEST_MOCK_DEFINITIONS_H
#define TEST_MOCK_DEFINITIONS_H

#include <stdint.h>

extern uint32_t test_trigger_ram[4];

#define BTL_TRIGGER_RAM_START ((uintptr_t)&test_trigger_ram[0])

#endif
