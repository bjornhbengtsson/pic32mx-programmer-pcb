#!/usr/bin/env python3
"""Run package-level tests that do not require MPLAB XC32."""

from __future__ import annotations

import shutil
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str]) -> None:
    print("+", " ".join(command))
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    suite = unittest.defaultTestLoader.discover(str(ROOT / "tests"), pattern="test_*.py")
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful():
        return 1

    compiler = shutil.which("gcc") or shutil.which("clang")
    if compiler:
        output = ROOT / "tests" / ".bootloader_app_host_test"
        run([
            compiler,
            "-std=c11",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-Itests/mocks",
            "-Isource_overrides",
            "source_overrides/bootloader_app.c",
            "tests/test_bootloader_app_host.c",
            "-o",
            str(output),
        ])
        run([str(output)])
        output.unlink(missing_ok=True)
    else:
        print("WARNING: gcc/clang not installed; C host compilation skipped.")

    print("PASS: package-level host checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
