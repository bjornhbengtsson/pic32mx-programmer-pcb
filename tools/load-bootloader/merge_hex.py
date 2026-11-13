"""Merge the bootloader and an application hex into one ICSP image.

Used to build firmware/prebuilt/bootloader_plus_led_test.hex so a lab tech
can check a chip end to end (bootloader -> jump -> app) with only a Snap.
Fails if the two images overlap.

    python -I tools/load-bootloader/merge_hex.py BOOT.hex APP.hex OUT.hex
"""
import sys


def read_hex(path):
    mem, base = {}, 0
    with open(path) as f:
        for n, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            raw = bytes.fromhex(line[1:])
            if sum(raw) & 0xFF:
                raise SystemExit(f"{path}:{n}: bad checksum")
            count, addr, rtype, data = raw[0], (raw[1] << 8) | raw[2], raw[3], raw[4:4 + raw[0]]
            if rtype == 0:
                for i, b in enumerate(data):
                    mem[base + addr + i] = b
            elif rtype == 4:
                base = ((data[0] << 8) | data[1]) << 16
            elif rtype == 1:
                break
    return mem


def write_hex(mem, path):
    out, cur_hi = [], None
    addrs = sorted(mem)
    i = 0
    while i < len(addrs):
        start = addrs[i]
        hi = start >> 16
        if hi != cur_hi:
            rec = bytes([2, 0, 0, 4, hi >> 8, hi & 0xFF])
            out.append(":" + (rec + bytes([(-sum(rec)) & 0xFF])).hex().upper())
            cur_hi = hi
        chunk = [mem[start]]
        while (i + len(chunk) < len(addrs) and addrs[i + len(chunk)] == start + len(chunk)
               and len(chunk) < 16 and ((start + len(chunk)) >> 16) == hi):
            chunk.append(mem[start + len(chunk)])
        rec = bytes([len(chunk), (start >> 8) & 0xFF, start & 0xFF, 0]) + bytes(chunk)
        out.append(":" + (rec + bytes([(-sum(rec)) & 0xFF])).hex().upper())
        i += len(chunk)
    out.append(":00000001FF")
    with open(path, "w", newline="\r\n") as f:
        f.write("\n".join(out) + "\n")


def main():
    boot, app, dst = sys.argv[1:4]
    a, b = read_hex(boot), read_hex(app)
    overlap = set(a) & set(b)
    if overlap:
        raise SystemExit(f"images overlap at {len(overlap)} addresses, first 0x{min(overlap):08X}")
    merged = {**a, **b}
    write_hex(merged, dst)
    if read_hex(dst) != merged:
        raise SystemExit("round-trip check failed")
    print(f"OK: {len(a)} + {len(b)} bytes -> {dst}")


if __name__ == "__main__":
    main()
