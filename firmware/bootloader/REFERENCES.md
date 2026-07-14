# Primary references

Accessed during the July 2026 design review.

## Microchip device and programming documents

- PIC32MX534F064H product page  
  https://www.microchip.com/en-us/product/pic32mx534f064h
- PIC32MX5XX/6XX/7XX Family Data Sheet, DS60001156K  
  https://ww1.microchip.com/downloads/en/DeviceDoc/PIC32MX5XX-6XX-7XX-Family-Data-Sheet-DS60001156K.pdf
- PIC32 Flash Programming Specification, DS60001145  
  https://ww1.microchip.com/downloads/aemDocuments/documents/MCU32/ProductDocuments/ProgrammingSpecifications/PIC32-Flash-Programming-Specification-DS60001145.pdf
- PIC32MX534/564/664/764 Family Silicon Errata, DS80000511L  
  https://ww1.microchip.com/downloads/aemDocuments/documents/MCU32/ProductDocuments/Errata/PIC32MX534564664764_Family_DS80000511L.pdf

## Harmony USB HID bootloader

- Official repository  
  https://github.com/Microchip-MPLAB-Harmony/bootloader_apps_usb
- USB Device HID bootloader example documentation  
  https://onlinedocs.microchip.com/oxy/GUID-90F6CA10-E41C-4317-A3AA-CB049A76D4F0-en-US-5/GUID-BDA62187-954D-482E-9B03-29797BA6ABA8.html
- Closest PIC32MX reference project  
  https://github.com/Microchip-MPLAB-Harmony/bootloader_apps_usb/tree/master/apps/usb_device_hid_bootloader/bootloader/firmware/pic32mx_125_sk.X
- Reference test application  
  https://github.com/Microchip-MPLAB-Harmony/bootloader_apps_usb/tree/master/apps/usb_device_hid_bootloader/test_app/firmware/pic32mx_125_sk.X

## Programmer/debugger documents

- MPLAB PICkit 4 In-Circuit Debugger User's Guide  
  https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/MPLAB-PICkit-4-In-Circuit-Debugger-Users-Guide-DS50002751.pdf
- MPLAB Snap In-Circuit Debugger User's Guide  
  https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/UserGuides/MPLAB-Snap-In-Circuit-Debugger-User-Guide-50002787.pdf

## Project-specific supplied notes

The supplied nine-page project notes were also reviewed for the intended 8 MHz crystal, clamshell fixture, ICSP header, VCAP, USB pins, PICkit/Snap workflow, and board assumptions. Exact LED and switch GPIO net labels were not legible enough to use safely.
