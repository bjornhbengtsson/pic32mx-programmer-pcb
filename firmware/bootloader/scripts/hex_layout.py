#!/usr/bin/env python3
"""Validate PIC32MX534F064H Intel HEX address boundaries."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

PFM_START = 0x1D000000
PFM_END = 0x1D010000
BOOTLOADER_END = 0x1D008000
BFM_START = 0x1FC00000
BFM_END = 0x1FC03000


class HexError(ValueError):
    pass


def physical_address(address: int) -> int:
    """Map PIC32 KSEG0/KSEG1 virtual aliases to physical address."""
    if 0x80000000 <= address <= 0xBFFFFFFF:
        return address & 0x1FFFFFFF
    return address


def parse_hex(path: Path) -> Dict[int, int]:
    memory: Dict[int, int] = {}
    upper_linear = 0
    upper_segment = 0
    eof_seen = False

    for line_no, raw in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        if not line.startswith(":"):
            raise HexError(f"{path}:{line_no}: record does not start with ':'")

        try:
            record = bytes.fromhex(line[1:])
        except ValueError as exc:
            raise HexError(f"{path}:{line_no}: invalid hexadecimal text") from exc

        if len(record) < 5:
            raise HexError(f"{path}:{line_no}: record is too short")

        count = record[0]
        if len(record) != count + 5:
            raise HexError(
                f"{path}:{line_no}: byte count says {count}, record has {len(record)-5}"
            )
        if sum(record) & 0xFF:
            raise HexError(f"{path}:{line_no}: checksum failure")

        offset = (record[1] << 8) | record[2]
        record_type = record[3]
        data = record[4 : 4 + count]

        if record_type == 0x00:
            base = upper_linear if upper_linear else upper_segment
            for index, value in enumerate(data):
                absolute = base + offset + index
                physical = physical_address(absolute)
                previous = memory.get(physical)
                if previous is not None and previous != value:
                    raise HexError(
                        f"{path}:{line_no}: conflicting data at 0x{physical:08X}"
                    )
                memory[physical] = value
        elif record_type == 0x01:
            eof_seen = True
            break
        elif record_type == 0x02:
            if count != 2:
                raise HexError(f"{path}:{line_no}: bad extended segment record")
            upper_segment = int.from_bytes(data, "big") << 4
            upper_linear = 0
        elif record_type == 0x04:
            if count != 2:
                raise HexError(f"{path}:{line_no}: bad extended linear record")
            upper_linear = int.from_bytes(data, "big") << 16
            upper_segment = 0
        elif record_type in (0x03, 0x05):
            # Start-address metadata does not contain programmed bytes.
            continue
        else:
            raise HexError(
                f"{path}:{line_no}: unsupported record type 0x{record_type:02X}"
            )

    if not eof_seen:
        raise HexError(f"{path}: EOF record not found")
    if not memory:
        raise HexError(f"{path}: no data records found")
    return memory


def segments(addresses: Iterable[int]) -> List[Tuple[int, int]]:
    ordered = sorted(set(addresses))
    if not ordered:
        return []

    result: List[Tuple[int, int]] = []
    start = previous = ordered[0]
    for address in ordered[1:]:
        if address != previous + 1:
            result.append((start, previous + 1))
            start = address
        previous = address
    result.append((start, previous + 1))
    return result


def classify(memory: Dict[int, int], mode: str) -> dict:
    errors: List[str] = []
    warnings: List[str] = []
    programmed = set(memory)

    in_pfm = {a for a in programmed if PFM_START <= a < PFM_END}
    in_bfm = {a for a in programmed if BFM_START <= a < BFM_END}
    outside = programmed - in_pfm - in_bfm

    boot_pfm = {a for a in in_pfm if a < BOOTLOADER_END}
    app_pfm = {a for a in in_pfm if a >= BOOTLOADER_END}

    if mode == "bootloader":
        if not boot_pfm:
            errors.append("bootloader HEX has no bytes in the bootloader PFM region")
        if app_pfm:
            errors.append(
                "bootloader HEX writes the application region at/above 0x1D008000"
            )
        if not in_bfm:
            warnings.append(
                "bootloader HEX has no Boot Flash/config bytes; confirm reset/config strategy"
            )
    elif mode == "application":
        if not app_pfm:
            errors.append("application HEX has no bytes in the application PFM region")
        if boot_pfm:
            errors.append(
                "application HEX writes the bootloader region below 0x1D008000"
            )
        if in_bfm:
            errors.append(
                "application HEX writes Boot Flash/configuration words; remove config pragmas"
            )
    else:
        raise ValueError(mode)

    if outside:
        warnings.append(
            f"{len(outside)} programmed bytes lie outside target PFM/BFM ranges"
        )

    return {
        "mode": mode,
        "status": "PASS" if not errors else "FAIL",
        "programmed_bytes": len(programmed),
        "pfm_bytes": len(in_pfm),
        "bootloader_pfm_bytes": len(boot_pfm),
        "application_pfm_bytes": len(app_pfm),
        "boot_flash_bytes": len(in_bfm),
        "outside_bytes": len(outside),
        "segments": [
            {"start": f"0x{s:08X}", "end_exclusive": f"0x{e:08X}", "bytes": e - s}
            for s, e in segments(programmed)
        ],
        "errors": errors,
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("hex_file", type=Path)
    parser.add_argument("--mode", choices=("bootloader", "application"), required=True)
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    try:
        memory = parse_hex(args.hex_file)
        report = classify(memory, args.mode)
    except (OSError, HexError) as exc:
        report = {
            "mode": args.mode,
            "status": "FAIL",
            "errors": [str(exc)],
            "warnings": [],
        }

    if args.as_json:
        print(json.dumps(report, indent=2))
    else:
        print(f"{args.hex_file}: {report['status']} ({args.mode})")
        for item in report.get("segments", []):
            print(
                f"  {item['start']}..{item['end_exclusive']} "
                f"({item['bytes']} bytes)"
            )
        for warning in report.get("warnings", []):
            print(f"WARNING: {warning}")
        for error in report.get("errors", []):
            print(f"ERROR: {error}")

    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
