#!/usr/bin/env python3
"""docs/app-store/screenshots/{tr,en}/*.png -> contact-sheet.png (iki satır: TR, EN)."""
import pathlib
from PIL import Image, ImageDraw, ImageFont
docs = pathlib.Path(__file__).resolve().parents[3] / 'docs' / 'app-store' / 'screenshots'
rows = [sorted((docs / l).glob('*.png')) for l in ('tr', 'en')]
W, H, pad, label = 440, 956, 30, 70
cols = max(len(r) for r in rows)
sheet = Image.new('RGB', (pad + cols * (W + pad), pad + len(rows) * (H + label + pad)), (246, 248, 247))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 26)
except OSError:
    font = ImageFont.load_default()
for r, files in enumerate(rows):
    for c, f in enumerate(files):
        im = Image.open(f).convert('RGB').resize((W, H), Image.LANCZOS)
        x, y = pad + c * (W + pad), pad + r * (H + label + pad)
        sheet.paste(im, (x, y))
        d.text((x, y + H + 16), f'{f.parent.name}/{f.name}', fill=(40, 45, 43), font=font)
out = docs / 'contact-sheet.png'
sheet.save(out, optimize=True)
print('wrote', out, sheet.size)
