/*
 * Configuration bits for:
 *   PIC32MX534F064H
 *   8 MHz external crystal
 *   80 MHz SYSCLK
 *   48 MHz USB clock
 *   PGEC1/PGED1 ICSP
 *
 * Add this file to the BOOTLOADER project only.
 * Remove/disable any duplicate configuration-bit source generated elsewhere.
 */

#include <xc.h>

#pragma config FPLLMUL  = MUL_20
#pragma config FPLLIDIV = DIV_2
#pragma config FPLLODIV = DIV_1

#pragma config UPLLEN   = ON
#pragma config UPLLIDIV = DIV_2

#pragma config FNOSC    = PRIPLL
#pragma config FSOSCEN  = OFF
#pragma config IESO     = OFF
#pragma config POSCMOD  = HS
#pragma config OSCIOFNC = OFF
#pragma config FPBDIV   = DIV_1
#pragma config FCKSM    = CSDCMD

#pragma config WDTPS    = PS1048576
#pragma config FWDTEN   = OFF

#pragma config DEBUG    = OFF
#pragma config JTAGEN  = OFF
#pragma config ICESEL  = ICS_PGx1

#pragma config PWP      = OFF
#pragma config BWP      = OFF
#pragma config CP       = OFF

#pragma config FVBUSONIO = ON
#pragma config FUSBIDIO  = ON

#pragma config USERID   = 0x534B
