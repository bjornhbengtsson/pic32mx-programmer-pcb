# Bootloader MPLAB X project

The complete source of the USB HID bootloader that runs on the board: the
MPLAB X project and its MCC / Harmony 3 generated code, with this board's
changes applied.

```text
generated_projects/
├── Bootloader.X/            MPLAB X project (open this)
│   ├── Bootloader_default/  MCC configuration (components, settings)
│   ├── nbproject/           project and makefiles
│   └── mcc-manifest-*.yml   Harmony package versions used
└── src/                     source: main.c, app.c (= source_overrides/bootloader_app.c),
    │                        bootloader_board.h, and MCC-generated code
    └── config/default/      Harmony bootloader, USB device + HID, NVM, startup, btl.ld
```

The project expects `src/` next to `Bootloader.X/`, as here.

| Tool | Version used |
|---|---|
| MPLAB X IDE | v6.30 |
| MPLAB XC32 | v5.10 |
| PIC32MX_DFP | 1.6.369 (build), 1.7.380 (IPE) |
| Harmony 3 bootloader / csp / usb | see `Bootloader.X/mcc-manifest-generated-success.yml` |

**You don't need to build this to load chips.** The tested image is
[`../../prebuilt/bootloader_pic32mx534.hex`](../../prebuilt/). Build from here
only to change the bootloader.

## Build in MPLAB X (recommended)

1. **File → Open Project…** → select `Bootloader.X`.
2. MPLAB X may ask about missing compiler/pack versions; pick XC32 v5.10 and
   the PIC32MX DFP if offered.
3. Right-click the project → **Clean and Build**.
4. Output: `Bootloader.X/dist/default/production/Bootloader.X.production.hex`.
5. Check it before programming:

   ```powershell
   python firmware\bootloader\scripts\hex_layout.py --mode bootloader firmware\bootloader\generated_projects\Bootloader.X\dist\default\production\Bootloader.X.production.hex
   python firmware\bootloader\scripts\verify_project.py --bootloader firmware\bootloader\generated_projects\src
   ```

## Build from the command line

MPLAB X writes small machine-specific files (`.generated_files/`,
`nbproject/Makefile-genesis.properties`) when it opens a project; they are not
in the repo. Create them headlessly, then build:

```powershell
cd firmware\bootloader\generated_projects
& "C:\Program Files\Microchip\MPLABX\v6.30\mplab_platform\bin\prjMakefilesGenerator.bat" "$PWD\Bootloader.X"
cd Bootloader.X
$env:PATH = "C:\Program Files\Microchip\MPLABX\v6.30\gnuBins\GnuWin32\bin;" + $env:PATH
make -f nbproject/Makefile-default.mk CONF=default SUBPROJECTS= .build-conf
```

> Keep the repository in a **short path** (for example `C:\work\pic32mx-programmer-pcb`).
> MPLAB's bundled `make` fails with "No such file or directory" when paths
> pass Windows' 260-character limit.

## Changing settings in MCC

1. Open the project, then open **MCC**. The configuration loads from
   `Bootloader.X/Bootloader_default/`.
2. Make your change and click **Generate**.
3. **Always** run the patch script afterwards. MCC resets several of this
   board's settings:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\mcc-patch\Apply-BootloaderPatches.ps1 -ProjectSrc firmware\bootloader\generated_projects\src
   ```

4. Clean and Build, run the two checks above, then program it with a Snap and
   re-run the hardware tests in [`../VALIDATION_STATUS.md`](../VALIDATION_STATUS.md).

## Reproducibility

A fresh copy of this folder, built with `prjMakefilesGenerator` + `make`,
produces the **same 214 functions with the same sizes** as the tested image.
The hex is not byte-identical, because the generated makefile links the object
files in a different order, which shifts addresses. Treat
`prebuilt/bootloader_pic32mx534.hex` (IPE checksum `FF12BE4E`) as the reference
image; a rebuilt image needs the hardware tests before it replaces it.

Generated files keep Microchip's licence headers; see
[`../THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).
