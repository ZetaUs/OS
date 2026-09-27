import sys
from PIL import Image
import numpy as np

# VGA mode 13h standard palette (256 colors)
VGA_PALETTE = [
    # Standard 16 colors
    (0, 0, 0), (0, 0, 168), (0, 168, 0), (0, 168, 168),
    (168, 0, 0), (168, 0, 168), (168, 84, 0), (168, 168, 168),
    (84, 84, 84), (84, 84, 252), (84, 252, 84), (84, 252, 252),
    (252, 84, 84), (252, 84, 252), (252, 252, 84), (252, 252, 252),
]

# Generate remaining 240 colors (6x6x6 color cube + 24 grays)
for r in range(6):
    for g in range(6):
        for b in range(6):
            if r == 0 and g == 0 and b == 0:
                continue
            VGA_PALETTE.append((
                int(r * 255 / 5),
                int(g * 255 / 5),
                int(b * 255 / 5)
            ))

# Add 24 gray shades
for i in range(24):
    gray = int(i * 255 / 23)
    VGA_PALETTE.append((gray, gray, gray))

def rgb_to_vga13(r, g, b):
    """Convert RGB to VGA mode 13h palette index - Gold (#cacf09)"""
    # Target color: #cacf09 = RGB(202, 207, 9)
    # Find closest VGA palette color to this gold
    if r > 20 or g > 20 or b > 20:
        return 14  # VGA palette index 14 is closest to gold/yellow
    return 0  # Black/transparent

def convert_image(input_file, output_file, max_width, max_height, var_name):
    """Convert image to C++ array for VGA mode 13h"""
    img = Image.open(input_file).convert('RGBA')
    
    # Resize to fit within max dimensions while maintaining aspect ratio
    img.thumbnail((max_width, max_height), Image.LANCZOS)
    
    width, height = img.size
    pixels = []
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            if a < 128:
                pixels.append(0)  # Transparent -> black
            else:
                pixels.append(rgb_to_vga13(r, g, b))
    
    # Write C++ header
    with open(output_file, 'w') as f:
        f.write(f"// Auto-generated from {input_file}\n")
        f.write(f"// Size: {width}x{height}\n\n")
        f.write(f"static const uint16_t {var_name}_width = {width};\n")
        f.write(f"static const uint16_t {var_name}_height = {height};\n")
        f.write(f"static const uint8_t {var_name}_data[{width * height}] = {{\n")
        
        for i in range(0, len(pixels), 16):
            row = pixels[i:i+16]
            f.write("    " + ", ".join(str(p) for p in row))
            if i + 16 < len(pixels):
                f.write(",\n")
            else:
                f.write("\n")
        
        f.write("};\n\n")
        
        # Add draw function
        f.write(f"static void draw_{var_name}(uint16_t x, uint16_t y) {{\n")
        f.write(f"    for (uint16_t row = 0; row < {var_name}_height; ++row) {{\n")
        f.write(f"        for (uint16_t col = 0; col < {var_name}_width; ++col) {{\n")
        f.write(f"            uint8_t color = {var_name}_data[row * {var_name}_width + col];\n")
        f.write(f"            if (color != 0) {{\n")
        f.write(f"                vram[(y + row) * 320u + x + col] = color;\n")
        f.write(f"            }}\n")
        f.write(f"        }}\n")
        f.write(f"    }}\n")
        f.write(f"}}\n\n")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: convert_images.py <input_file> <output_file> <max_width> <max_height>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    max_width = int(sys.argv[3])
    max_height = int(sys.argv[4])
    
    var_name = input_file.split('.')[0].replace('-', '_')
    convert_image(input_file, output_file, max_width, max_height, var_name)
    print(f"Converted {input_file} -> {output_file}")