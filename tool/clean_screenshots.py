"""Wipes the floating "+" button out of the README screenshots that have one.

Flutter's test renderer draws a thick black outline around an extended floating action
button, which a real phone does not show (it happens even with an unthemed Flutter button).
The pictures are better without it than with it.

Run after:  flutter test tool/screenshots_test.dart
            python tool/clean_screenshots.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

SHOTS = Path(__file__).resolve().parent.parent / "docs" / "screenshots"
BACKGROUND = (0xF4, 0xF7, 0xF6)  # the light page colour; these screens are empty down there

# These three screens are short, so after the button is gone the rest of the picture is
# empty page. Each is cropped to just below its content (a fraction of the height).
KEEP = {"budgets": 0.63, "goals": 0.42, "dhar": 0.42}

for name, keep in KEEP.items():
    path = SHOTS / f"{name}.png"
    img = Image.open(path).convert("RGB")
    w, h = img.size
    ImageDraw.Draw(img).rectangle((int(w * 0.44), int(h * 0.885), w, h), fill=BACKGROUND)
    img = img.crop((0, 0, w, int(h * keep)))
    img.save(path, optimize=True)
    print("cleaned", path.name, img.size)
