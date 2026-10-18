from PIL import Image, ImageOps, ImageEnhance, ImageColor
import os

INPUT_PATH = 'assets/images/appicon.png'
OUTPUT_DIR = 'assets/app_icons'

def ensure_dir(d):
    if not os.path.exists(d):
        os.makedirs(d)

def generate_variants():
    ensure_dir(OUTPUT_DIR)
    
    try:
        raw_original = Image.open(INPUT_PATH).convert('RGBA')
        # FORCE SQUARE RESIZE (1024x1024)
        original = raw_original.resize((1024, 1024), Image.LANCZOS)
        print(f"Loaded {INPUT_PATH} and resized to 1024x1024")
    except FileNotFoundError:
        print(f"Error: {INPUT_PATH} not found.")
        return

    # 1. Default
    original.save(os.path.join(OUTPUT_DIR, 'preview_default.png'))
    print("Generated Default")

    # Helper to colorize if transparent, or tint if solid
    # We check if image has transparency roughly
    extrema = original.getextrema() 
    has_transparency = extrema[3][0] < 255

    # 2. Dark (Midnight)
    # If transparent: Dark BG, White Icon
    # If solid: Grayscale, Darken
    if has_transparency:
        dark = Image.new('RGBA', original.size, (20, 20, 20, 255))
        # Composite: Icon as white?
        # Extract alpha to use as mask for white fill
        alpha = original.split()[3]
        icon_white = Image.new('RGBA', original.size, (255, 255, 255, 255))
        icon_white.putalpha(alpha)
        dark.alpha_composite(icon_white)
        dark.save(os.path.join(OUTPUT_DIR, 'preview_dark.png'))
    else:
        # Solid: Turn to grayscale, then darken
        gray = ImageOps.grayscale(original).convert('RGB')
        enhancer = ImageEnhance.Brightness(gray)
        dark = enhancer.enhance(0.5) # Darken
        dark.save(os.path.join(OUTPUT_DIR, 'preview_dark.png'))
    print("Generated Dark")

    # 3. Light
    if has_transparency:
        light = Image.new('RGBA', original.size, (255, 255, 255, 255))
        alpha = original.split()[3]
        icon_black = Image.new('RGBA', original.size, (0, 0, 0, 255))
        icon_black.putalpha(alpha)
        light.alpha_composite(icon_black)
        light.save(os.path.join(OUTPUT_DIR, 'preview_light.png'))
    else:
        # Solid: Invert? Or High Brightness
        # Invert usually looks cool for light mode vs dark
        try:
             light = ImageOps.invert(original.convert('RGB'))
        except:
             light = original.convert('RGB')
        light.save(os.path.join(OUTPUT_DIR, 'preview_light.png'))
    print("Generated Light")

    # 4. Gold
    # Sepia tone
    if has_transparency:
        gold_bg = Image.new('RGBA', original.size, (0, 0, 0, 255))
        alpha = original.split()[3]
        icon_gold = Image.new('RGBA', original.size, (255, 215, 0, 255))
        icon_gold.putalpha(alpha)
        gold_bg.alpha_composite(icon_gold)
        gold_bg.save(os.path.join(OUTPUT_DIR, 'preview_gold.png'))
    else:
        # Solid: Grayscale -> Colorize
        gray = ImageOps.grayscale(original)
        gold = ImageOps.colorize(gray, black="black", white="#FFD700")
        gold.save(os.path.join(OUTPUT_DIR, 'preview_gold.png'))
    print("Generated Gold")

    # 5. Neon
    # Cyan/Magenta
    if has_transparency:
        neon_bg = Image.new('RGBA', original.size, (10, 10, 40, 255))
        alpha = original.split()[3]
        icon_neon = Image.new('RGBA', original.size, (0, 255, 255, 255)) # Cyan
        icon_neon.putalpha(alpha)
        neon_bg.alpha_composite(icon_neon)
        neon_bg.save(os.path.join(OUTPUT_DIR, 'preview_neon.png'))
    else:
        # Solid: Hue Rotate?
        # A simple hack: convert RGB -> HSV, shift Hue, back to RGB
        # Pillow doesn't do HSV rotation easily.
        # Let's just colorize with Cyan/Purple
        gray = ImageOps.grayscale(original)
        neon = ImageOps.colorize(gray, black="#200020", white="#00FFFF") 
        neon.save(os.path.join(OUTPUT_DIR, 'preview_neon.png'))
    print("Generated Neon")
    
    # 6. Retro
    if has_transparency:
        retro_bg = Image.new('RGBA', original.size, (240, 230, 140, 255)) # Khaki
        alpha = original.split()[3]
        icon_retro = Image.new('RGBA', original.size, (139, 69, 19, 255)) # SaddleBrown
        icon_retro.putalpha(alpha)
        retro_bg.alpha_composite(icon_retro)
        retro_bg.save(os.path.join(OUTPUT_DIR, 'preview_retro.png'))
    else:
        gray = ImageOps.grayscale(original)
        retro = ImageOps.colorize(gray, black="#5c3a21", white="#d6c68b")
        retro.save(os.path.join(OUTPUT_DIR, 'preview_retro.png'))
    print("Generated Retro")

if __name__ == "__main__":
    generate_variants()
