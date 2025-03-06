#!/usr/bin/env python3
from PIL import Image, ImageDraw
import os

# Create the AppIcon.appiconset directory if it doesn't exist
os.makedirs("Soul AI/Assets.xcassets/AppIcon.appiconset", exist_ok=True)

# Define the icon sizes needed for iOS
icon_sizes = [
    (20, 1), (20, 2), (20, 3),  # Notification
    (29, 1), (29, 2), (29, 3),  # Settings
    (40, 1), (40, 2), (40, 3),  # Spotlight
    (60, 2), (60, 3),           # App icon (iPhone)
    (76, 1), (76, 2),           # App icon (iPad)
    (83.5, 2),                  # App icon (iPad Pro)
    (1024, 1)                   # App Store
]

# Create a 1024x1024 image with a black background
base_img = Image.new('RGB', (1024, 1024), color='black')
draw = ImageDraw.Draw(base_img)

# Draw the turquoise cross
turquoise = (92, 214, 186)  # #5CD6BA in RGB
draw.rectangle([384, 128, 640, 896], fill=turquoise)  # Vertical bar
draw.rectangle([128, 384, 896, 640], fill=turquoise)  # Horizontal bar

# Save the base image
base_img.save("Soul AI/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")

# Generate all required sizes
for size, scale in icon_sizes:
    pixel_size = int(size * scale)
    resized_img = base_img.resize((pixel_size, pixel_size), Image.LANCZOS)
    
    if size == 83.5:
        # Special case for iPad Pro
        filename = f"AppIcon-{int(size*10)}-{int(scale)}x.png"
    else:
        filename = f"AppIcon-{int(size)}-{int(scale)}x.png"
    
    resized_img.save(f"Soul AI/Assets.xcassets/AppIcon.appiconset/{filename}")

# Create the Contents.json file
contents_json = """
{
  "images" : [
    {
      "filename" : "AppIcon-20-1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20-2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20-3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29-1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29-2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29-3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40-1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40-2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40-3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60-2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60-3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-20-1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20-2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29-1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29-2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40-1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40-2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-76-1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-76-2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-835-2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

with open("Soul AI/Assets.xcassets/AppIcon.appiconset/Contents.json", "w") as f:
    f.write(contents_json)

print("App icon set generated successfully!") 