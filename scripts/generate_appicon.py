#!/usr/bin/env python3
"""Generate 1024 App Icons: light / dark / tinted with orange counter badge."""
import base64, zlib, pathlib
from PIL import Image, ImageDraw, ImageFilter

MASK_B64 = pathlib.Path(__file__).with_name("mask.b64").read_text().strip()

SIZE = 1024
ORANGE = (255, 122, 24)

def mask_image():
    packed = zlib.decompress(base64.b64decode(MASK_B64))
    pixels = []
    for byte in packed:
        for i in range(8):
            pixels.append(255 if (byte & (0x80 >> i)) else 0)
    pixels = pixels[: SIZE * SIZE]
    m = Image.new("L", (SIZE, SIZE))
    m.putdata(pixels)
    return m

def compose(fg, bg, m):
    canvas = Image.new("RGB", (SIZE, SIZE), bg)
    layer = Image.new("RGB", (SIZE, SIZE), fg)
    canvas.paste(layer, mask=m)
    return canvas

def add_badge(base, fill, stroke, glyph):
    im = base.convert("RGBA")
    r, margin = 168, 72
    x1 = SIZE - margin - r * 2
    y1 = SIZE - margin - r * 2
    x2 = SIZE - margin
    y2 = SIZE - margin
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse((x1 + 8, y1 + 12, x2 + 8, y2 + 12), fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(10))
    im = Image.alpha_composite(im, shadow)
    d = ImageDraw.Draw(im)
    d.ellipse((x1, y1, x2, y2), fill=fill, outline=stroke, width=14)
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
    inner = 46
    d.arc((cx - inner, cy - inner, cx + inner, cy + inner), start=130, end=50, fill=glyph, width=16)
    d.line((cx, cy, cx + 28, cy - 22), fill=glyph, width=10)
    d.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=glyph)
    return im.convert("RGB"), (x1, y1, x2, y2)

def main():
    dest = pathlib.Path("AILimits/Assets.xcassets/AppIcon.appiconset")
    dest.mkdir(parents=True, exist_ok=True)
    m = mask_image()
    light, box = add_badge(compose((0, 0, 0), (255, 255, 255), m), ORANGE, (255, 255, 255), (255, 255, 255))
    dark, _ = add_badge(compose((255, 255, 255), (0, 0, 0), m), ORANGE, (0, 0, 0), (255, 255, 255))
    tinted = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    tinted.paste((0, 0, 0, 255), mask=m)
    ImageDraw.Draw(tinted).ellipse(box, fill=(0, 0, 0, 255))
    light.save(dest / "AppIcon.png", "PNG", optimize=True)
    dark.save(dest / "AppIcon-dark.png", "PNG", optimize=True)
    tinted.save(dest / "AppIcon-tinted.png", "PNG", optimize=True)
    print("wrote", dest)

if __name__ == "__main__":
    main()
