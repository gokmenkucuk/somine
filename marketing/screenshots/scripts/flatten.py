#!/usr/bin/env python3
"""PNG'leri alfa kanalsız RGB olarak yeniden yazar (App Store alfa istemez)."""
import sys
from PIL import Image
for p in sys.argv[1:]:
    im = Image.open(p)
    if im.mode != 'RGB':
        bg = Image.new('RGB', im.size, (255, 255, 255))
        im = im.convert('RGBA'); bg.paste(im, mask=im.split()[3]); im = bg
    im.save(p, optimize=True)
