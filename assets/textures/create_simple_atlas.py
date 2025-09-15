#!/usr/bin/env python3
"""
Simple script to create a basic texture atlas for the Minecraft-like game.
This creates a 256x256 PNG with 16x16 block textures.
"""

from PIL import Image, ImageDraw
import os

def create_block_texture(size=16):
    """Create a base texture"""
    return Image.new('RGB', (size, size))

def create_grass_top():
    img = create_block_texture()
    # Fill with green
    for x in range(16):
        for y in range(16):
            # Add some noise
            noise = abs(hash((x, y)) % 20 - 10) / 100.0
            green = int(76 + noise * 20)  # Base green with variation
            img.putpixel((x, y), (25, green, 25))
    return img

def create_grass_side():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            if y < 3:  # Top grass part
                img.putpixel((x, y), (38, 102, 38))
            else:  # Dirt part
                noise = abs(hash((x, y)) % 10) / 100.0
                brown = int(102 + noise * 20)
                img.putpixel((x, y), (brown, 64, 38))
    return img

def create_dirt():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            noise = abs(hash((x, y)) % 15) / 100.0
            brown = int(102 + noise * 25)
            img.putpixel((x, y), (brown, 64, 38))
    return img

def create_stone():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            noise = abs(hash((x, y)) % 20) / 100.0
            gray = int(128 + noise * 30)
            img.putpixel((x, y), (gray, gray, gray))
    return img

def create_sand():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            noise = abs(hash((x, y)) % 10) / 100.0
            yellow = int(204 + noise * 15)
            img.putpixel((x, y), (yellow, 179, 102))
    return img

def create_wood_top():
    img = create_block_texture()
    center = 8
    for x in range(16):
        for y in range(16):
            # Create ring pattern
            distance = ((x - center) ** 2 + (y - center) ** 2) ** 0.5
            ring = abs(int(distance * 2) % 4 - 2) * 10
            brown = int(102 + ring)
            img.putpixel((x, y), (brown, 64, 38))
    return img

def create_wood_side():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            # Vertical grain
            grain = abs((x * 3) % 8 - 4) * 5
            brown = int(89 + grain)
            img.putpixel((x, y), (brown, 51, 25))
    return img

def create_leaves():
    img = create_block_texture()
    for x in range(16):
        for y in range(16):
            noise = abs(hash((x, y)) % 15) / 100.0
            green = int(76 + noise * 20)
            img.putpixel((x, y), (25, green, 25))
    return img

def main():
    # Create 256x256 atlas
    atlas = Image.new('RGB', (256, 256), (255, 0, 255))  # Magenta background
    
    # Block textures
    textures = [
        create_grass_top(),    # (0,0)
        create_grass_side(),   # (1,0) 
        create_dirt(),         # (2,0)
        create_stone(),        # (3,0)
        create_sand(),         # (0,1)
        create_wood_top(),     # (1,1)
        create_wood_side(),    # (2,1)
        create_leaves(),       # (3,1)
    ]
    
    # Place textures in atlas
    positions = [
        (0, 0), (1, 0), (2, 0), (3, 0),  # Row 0
        (0, 1), (1, 1), (2, 1), (3, 1),  # Row 1
    ]
    
    for i, (texture, (grid_x, grid_y)) in enumerate(zip(textures, positions)):
        x = grid_x * 16
        y = grid_y * 16
        atlas.paste(texture, (x, y))
    
    # Save atlas
    atlas.save('block_atlas.png')
    print("Created block_atlas.png")

if __name__ == '__main__':
    main()