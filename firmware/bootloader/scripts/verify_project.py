#!/usr/bin/env python3
"""Static checks for generated PIC32MX534 USB HID bootloader projects."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Iterable, List

TEXT_SUFFIXES = {
    ".c", ".h", ".ld", ".xml", ".properties", ".mk", ".mc3", ".mc4",
    ".yml", ".yaml", ".txt"
}


def collect_text(root: Path) -> str:
    chunks: List[str] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES and path.name not in {
            "Makefile", "configurations.xml"
        }:
            continue
        try:
            chunks.append(f"\n/* FILE: {path} */\n")
            chunks.append(path.read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            pass
    return "".join(chunks)


def compact(text: str) -> str:
    return re.sub(r"\s+", "", text).lower()


def require_any(errors: List[str], text: str, labels: Iterable[str], description: str) -> None:
    c = compact(text)
    if not any(compact(label) in c for label in labels):
        errors.append(description)


def warn_any(warnings: List[str], text: str, labels: Iterable[str], description: str) -> None:
    c = compact(text)
    if not any(compact(label) in c for label in labels):
        warnings.append(description)


def verify_common(root: Path, text: str, errors: List[str], warnings: List[str]) -> None:
    if not root.exists():
        errors.append(f"project path does not exist: {root}")
        return

    require_any(
        errors, text,
        ["PIC32MX534F064H", "32MX534F064H"],
        "target device PIC32MX534F064H not found"
    )

    stale = ["PIC32MX570F512L", "0x80000UL", "0x10000 - 16"]
    for value in stale:
        if value.lower() in text.lower():
            errors.append(f"stale reference-device value found: {value}")

    warn_any(
        warnings, text,
        ["CPU_CLOCK_FREQUENCY 80000000", "CPU_CLOCK_FREQUENCY=80000000",
         "80000000U", "80000000UL"],
        "80 MHz CPU clock text not found"
    )


def verify_bootloader(root: Path) -> dict:
    text = collect_text(root)
    errors: List[str] = []
    warnings: List[str] = []
    verify_common(root, text, errors, warnings)

    require_any(
        errors, text,
        ["FLASH_LENGTH (0x10000UL)", "FLASH_LENGTH(0x10000UL)",
         "FLASH_LENGTH 0x10000", "FLASH_LENGTH=0x10000"],
        "bootloader FLASH_LENGTH is not 0x10000"
    )
    require_any(
        errors, text,
        ["BOOTLOADER_SIZE 32768", "BOOTLOADER_SIZE=32768",
         "BOOTLOADER_SIZE 0x8000", "BOOTLOADER_SIZE=0x8000"],
        "32 KiB bootloader reservation not found"
    )
    require_any(
        errors, text,
        ["0x1d008000", "0x9d008000"],
        "application start/jump address 0x9D008000 not found"
    )
    require_any(
        errors, text,
        ["ORIGIN=0x9D000000,LENGTH=32768",
         "ORIGIN=0x9D000000,LENGTH=0x8000"],
        "bootloader linker region 0x9D000000/0x8000 not found"
    )
    require_any(
        errors, text,
        ["ORIGIN=0xA0000000+16,LENGTH=0x4000-16",
         "ORIGIN=0xA0000010,LENGTH=0x3FF0",
         "ORIGIN=0xA0000000+16,LENGTH=16384-16"],
        "16 KiB SRAM region with 16-byte trigger reservation not found"
    )
    require_any(
        errors, text,
        ["BTL_TRIGGER_PATTERN", "0x5048434D"],
        "RAM boot request pattern not found"
    )
    require_any(
        errors, text,
        ["FPLLIDIV=DIV_2", "FPLLIDIV = DIV_2"],
        "8 MHz PLL input divider setting not found"
    )
    require_any(
        errors, text,
        ["FPLLMUL=MUL_20", "FPLLMUL = MUL_20"],
        "PLL x20 setting not found"
    )
    require_any(
        errors, text,
        ["UPLLEN=ON", "UPLLEN = ON"],
        "USB PLL enable setting not found"
    )
    require_any(
        errors, text,
        ["ICESEL=ICS_PGx1", "ICESEL = ICS_PGx1"],
        "PGEC1/PGED1 ICESEL setting not found"
    )
    warn_any(
        warnings, text,
        ["0x003C", "0x3C", "0x3c"],
        "USB PID 0x003C not found in scanned source"
    )
    warn_any(
        warnings, text,
        ["0x04D8", "0x4D8", "0xd8,0x04", "0xD8, 0x04"],
        "USB VID 0x04D8 not found in scanned source"
    )

    return {
        "project": str(root),
        "kind": "bootloader",
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "warnings": warnings,
    }


def verify_application(root: Path) -> dict:
    text = collect_text(root)
    errors: List[str] = []
    warnings: List[str] = []
    verify_common(root, text, errors, warnings)

    require_any(
        errors, text,
        ["_RESET_ADDR=0xBD000000+0x8000",
         "_RESET_ADDR=0xBD008000"],
        "application reset address 0xBD008000 not found"
    )
    require_any(
        errors, text,
        ["_ebase_address=0x9D009000",
         "_ebase_address = 0x9D009000"],
        "application EBASE 0x9D009000 not found"
    )
    require_any(
        errors, text,
        ["ORIGIN=0x9D009000,LENGTH=0x7000",
         "ORIGIN=0x9D009000,LENGTH=28672"],
        "application normal-code region 0x9D009000/0x7000 not found"
    )
    require_any(
        errors, text,
        ["ORIGIN=0xBD008000,LENGTH=0x490"],
        "application reset-page region 0xBD008000 not found"
    )
    require_any(
        errors, text,
        ["ORIGIN=0xA0000000+16,LENGTH=0x4000-16",
         "ORIGIN=0xA0000010,LENGTH=0x3FF0",
         "ORIGIN=0xA0000000+16,LENGTH=16384-16"],
        "application SRAM region with trigger reservation not found"
    )

    config_pragmas = re.findall(r"#\s*pragma\s+config", text, flags=re.I)
    if config_pragmas:
        errors.append(
            "application project contains #pragma config; USB-loaded app must not update config words"
        )

    return {
        "project": str(root),
        "kind": "application",
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bootloader", type=Path)
    parser.add_argument("--application", type=Path)
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    if not args.bootloader and not args.application:
        parser.error("provide --bootloader and/or --application")

    reports = []
    if args.bootloader:
        reports.append(verify_bootloader(args.bootloader))
    if args.application:
        reports.append(verify_application(args.application))

    if args.as_json:
        print(json.dumps(reports, indent=2))
    else:
        for report in reports:
            print(f"{report['kind']}: {report['status']} - {report['project']}")
            for warning in report["warnings"]:
                print(f"  WARNING: {warning}")
            for error in report["errors"]:
                print(f"  ERROR: {error}")

    return 0 if all(r["status"] == "PASS" for r in reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
