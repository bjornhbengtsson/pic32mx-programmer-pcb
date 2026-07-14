from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "hex_layout.py"
SPEC = importlib.util.spec_from_file_location("hex_layout", MODULE_PATH)
hex_layout = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(hex_layout)


def record(address: int, record_type: int, data: bytes) -> str:
    payload = bytes([
        len(data),
        (address >> 8) & 0xFF,
        address & 0xFF,
        record_type,
    ]) + data
    checksum = (-sum(payload)) & 0xFF
    return ":" + (payload + bytes([checksum])).hex().upper()


def image(address: int, data: bytes) -> str:
    upper = (address >> 16) & 0xFFFF
    lower = address & 0xFFFF
    return "\n".join([
        record(0, 0x04, upper.to_bytes(2, "big")),
        record(lower, 0x00, data),
        record(0, 0x01, b""),
        "",
    ])


class HexLayoutTests(unittest.TestCase):
    def parse(self, text: str):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "image.hex"
            path.write_text(text, encoding="ascii")
            return hex_layout.parse_hex(path)

    def test_valid_bootloader(self):
        memory = self.parse(image(0x1D000000, bytes(range(16))))
        report = hex_layout.classify(memory, "bootloader")
        self.assertEqual(report["status"], "PASS")

    def test_bootloader_overlap_fails(self):
        memory = self.parse(image(0x1D008000, b"\x01\x02\x03\x04"))
        report = hex_layout.classify(memory, "bootloader")
        self.assertEqual(report["status"], "FAIL")

    def test_valid_application(self):
        memory = self.parse(image(0x1D008000, b"\x10\x20\x30\x40"))
        report = hex_layout.classify(memory, "application")
        self.assertEqual(report["status"], "PASS")

    def test_application_bootloader_overlap_fails(self):
        memory = self.parse(image(0x1D007FFC, b"\x10\x20\x30\x40"))
        report = hex_layout.classify(memory, "application")
        self.assertEqual(report["status"], "FAIL")

    def test_application_config_words_fail(self):
        memory = self.parse(image(0x1FC02FF0, b"\x00\x00\x00\x00"))
        report = hex_layout.classify(memory, "application")
        self.assertEqual(report["status"], "FAIL")

    def test_virtual_alias_maps_to_physical(self):
        memory = self.parse(image(0x9D008000, b"\xAA\x55"))
        self.assertIn(0x1D008000, memory)

    def test_bad_checksum(self):
        text = image(0x1D000000, b"\x01").replace("FF\n", "FE\n", 1)
        with self.assertRaises(hex_layout.HexError):
            self.parse(text)


if __name__ == "__main__":
    unittest.main()
