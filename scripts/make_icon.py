#!/usr/bin/env python3
"""Black spark-on-white 1024 icon approximating the provided mark."""
import struct, zlib, pathlib

SIZE = 1024

def px(x, y):
    cx, cy = SIZE/2, SIZE/2
    dx, dy = x - cx, y - cy
    r = (dx*dx + dy*dy) ** 0.5
    # outer ring
    ring = 340 < r < 430
    # diagonal spike (y ~ x)
    spike1 = abs(dy - dx) < 38 and r < 520
    spike2 = abs(dy + dx) < 28 and 180 < r < 480
    # inner crescent-ish
    inner = r < 210
    on = ring or spike1 or spike2
    if inner:
        on = False
    return (0,0,0,255) if on else (255,255,255,255)

raw = bytearray()
for y in range(SIZE):
    raw.append(0)
    for x in range(SIZE):
        raw.extend(px(x,y))

def chunk(tag, data):
    return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag+data) & 0xffffffff)

png = b'\x89PNG\r\n\x1a\n'
png += chunk(b'IHDR', struct.pack('>IIBBBBB', SIZE, SIZE, 8, 6, 0, 0, 0))
png += chunk(b'IDAT', zlib.compress(bytes(raw), 9))
png += chunk(b'IEND', b'')
out = pathlib.Path('AILimits/Assets.xcassets/AppIcon.appiconset/AppIcon.png')
out.parent.mkdir(parents=True, exist_ok=True)
out.write_bytes(png)
print('wrote', out, len(png))
