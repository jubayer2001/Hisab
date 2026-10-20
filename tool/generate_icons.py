"""Writes every Android icon and splash resource from the finished icon picture.

Run from the project root:  python -I tool/generate_icons.py

The picture is tool/reference/icon_final.png (1254 x 1254, full bleed, the design the
app's owner signed off; the sleeves run to its bottom and left edges). Needs Pillow, OpenCV and numpy.

What comes out:
  * the adaptive icon: the picture on a 108 dp canvas, scaled so everything that matters
    sits inside the 66 dp safe zone (the sleeves are allowed to run to the edge), over a
    background colour sampled from the picture so there is no seam;
  * a themed (monochrome) layer for Android 13+;
  * legacy launcher PNGs for Android 7 and older launchers;
  * a high-resolution splash picture, so the splash screen is sharp instead of an upscaled
    small icon;
  * docs/icon.png for the README.
"""

from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
FINAL = ROOT / "tool" / "reference" / "icon_final.png"

BASE = 1024
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
SAFE_RADIUS = 322          # of 1024: the 66 dp safe circle is 313 px in radius; a hair of slack


def load():
    img = Image.open(FINAL).convert("RGB")
    rgb = np.array(img)
    bg = tuple(int(v) for v in np.median(rgb[:60].reshape(-1, 3), axis=0))
    return img, rgb, bg


def essential_circle(rgb, bg):
    """The smallest circle holding everything that must stay visible: notes, hands, notebook
    and pen. The sleeves run off the picture's edge on purpose, so they do not count."""
    h, w = rgb.shape[:2]
    diff = np.abs(rgb.astype(int) - np.array(bg)).sum(axis=2)
    mask = (diff > 40).astype(np.uint8) * 255
    dark = ((rgb[..., 0] < 40) & (rgb[..., 1] < 135)).astype(np.uint8) * 255
    n, lab, st, _ = cv2.connectedComponentsWithStats(dark)
    for i in range(1, n):
        x, y, bw, bh, area = st[i]
        if area > 20000 and (x == 0 or y + bh >= h or x + bw >= w):
            mask[lab == i] = 0                                  # a sleeve
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    ys, xs = np.where(mask > 0)
    (cx, cy), r = cv2.minEnclosingCircle(np.column_stack([xs, ys]).astype(np.float32))
    return cx, cy, r


def place(img, circle, essential_radius, canvas):
    """The picture on a transparent square canvas, scaled so the essential circle has the
    wanted radius, with that circle's centre in the middle of the canvas."""
    cx, cy, r = circle
    scale = essential_radius / r
    size = round(img.width * scale)
    small = img.resize((size, size), Image.LANCZOS).convert("RGBA")
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.alpha_composite(small, (round(canvas / 2 - cx * scale), round(canvas / 2 - cy * scale)))
    return out, scale


def monochrome(placed, bg):
    """One-colour version for themed icons: light shapes (notes, hands, page) become solid,
    darker details become see-through, dark teal shapes (sleeves, pen) become a soft tint."""
    arr = np.array(placed).astype(float)
    lum = cv2.GaussianBlur(arr[..., :3] @ np.array([0.299, 0.587, 0.114]), (0, 0), 2)
    bg_lum = float(np.dot(bg, [0.299, 0.587, 0.114]))
    # a dead band around the background's brightness keeps its soft texture out of the result
    lighter = np.clip((lum - bg_lum - 16) / 40.0, 0, 1)
    darker = np.clip((bg_lum - lum - 9) / 10.0, 0, 1) * 0.5
    alpha = np.maximum(lighter, darker) * (arr[..., 3] / 255)
    out = np.zeros(arr.shape, np.uint8)
    out[..., :3] = 255
    out[..., 3] = np.round(alpha * 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def rounded(img, radius_fraction):
    mask = Image.new("L", (img.width * 2, img.height * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, mask.width - 1, mask.height - 1), radius=int(mask.width * radius_fraction), fill=255)
    mask = mask.resize(img.size, Image.LANCZOS)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def circle_cut(img, radius):
    """Keeps a soft-edged disc of the picture (for splash pictures the system does not mask)."""
    s = 4
    mask = Image.new("L", (img.width * s, img.height * s), 0)
    c = img.width * s / 2
    ImageDraw.Draw(mask).ellipse((c - radius * s, c - radius * s, c + radius * s, c + radius * s), fill=255)
    mask = mask.resize(img.size, Image.LANCZOS)
    out = img.copy()
    out.putalpha(mask)
    return out


def save(img, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, optimize=True)


def main():
    img, rgb, bg = load()
    circle = essential_circle(rgb, bg)
    hexbg = "#%02X%02X%02X" % bg
    print("background", hexbg, "essential circle centre (%.0f, %.0f) radius %.0f" % circle)

    # 1. adaptive icon layers
    foreground, scale = place(img, circle, SAFE_RADIUS, BASE)
    cx, cy, _ = circle
    # the picture's own edges must lie outside the 72 dp window (36 dp = 341 px radius) so no seam shows
    near = min(cx * scale, (img.width - cx) * scale, cy * scale, (img.height - cy) * scale)
    print("nearest picture edge: %.0f px from the middle (needs >= 341)" % near)
    assert near >= 341, "the picture's edge would show inside the icon"
    mono = monochrome(foreground, bg)
    for name, factor in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        save(foreground, folder / "ic_launcher_foreground.png", round(108 * factor))
        save(mono, folder / "ic_launcher_monochrome.png", round(108 * factor))
        save(rounded(img, 0.22), folder / "ic_launcher.png", round(48 * factor))

    (RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""", encoding="utf-8")
    (RES / "values" / "ic_launcher_background.xml").write_text(
        f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{hexbg}</color>
</resources>
""", encoding="utf-8")

    # 2. splash. Android 12+ masks a 288 dp picture to a 192 dp circle; it is supplied at
    # 4 px per dp (1152 px) and without density scaling, so it is never blown up from a small file.
    splash, _ = place(img, circle, 88 * 4, 288 * 4)
    nodpi = RES / "drawable-nodpi"
    nodpi.mkdir(parents=True, exist_ok=True)
    splash.save(nodpi / "splash_icon.png", optimize=True)
    # older Android shows the picture as-is, so cut it to a disc ourselves
    legacy_splash, _ = place(img, circle, 0.917 * 300, 640)
    circle_cut(legacy_splash, 300).save(nodpi / "splash_legacy.png", optimize=True)

    launch = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/ic_launcher_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_legacy" />
    </item>
</layer-list>
"""
    for folder in ("drawable", "drawable-v21"):
        (RES / folder).mkdir(parents=True, exist_ok=True)
        (RES / folder / "launch_background.xml").write_text(launch, encoding="utf-8")
    # AppCompat parents: the phone's fingerprint/PIN prompt (app lock) needs them on older Android.
    for folder, parent in (("values-v31", "Theme.AppCompat.Light.NoActionBar"), ("values-night-v31", "Theme.AppCompat.NoActionBar")):
        (RES / folder).mkdir(parents=True, exist_ok=True)
        (RES / folder / "styles.xml").write_text(
            f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="{parent}">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/ic_launcher_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>
    </style>
    <style name="NormalTheme" parent="{parent}">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
""", encoding="utf-8")

    # 3. README icon
    docs = ROOT / "docs"
    docs.mkdir(exist_ok=True)
    rounded(img, 0.22).resize((512, 512), Image.LANCZOS).save(docs / "icon.png", optimize=True)

    # 4. a sheet to look at while reviewing (not used by the app)
    sheet = Image.new("RGBA", (1500, 560), (244, 247, 246, 255))
    tile_bg = Image.new("RGBA", (BASE, BASE), bg + (255,))
    tile_bg.alpha_composite(foreground)
    x = 30
    for shape, size in (("circle", 480), ("squircle", 480)):
        mask = Image.new("L", (BASE * 2, BASE * 2), 0)
        d = ImageDraw.Draw(mask)
        # the visible window of an adaptive icon is 72 of 108 dp
        inset = round(BASE * 2 * (18 / 108))
        box = (inset, inset, BASE * 2 - inset - 1, BASE * 2 - inset - 1)
        if shape == "circle":
            d.ellipse(box, fill=255)
        else:
            d.rounded_rectangle(box, radius=round((box[2] - box[0]) * 0.28), fill=255)
        mask = mask.resize((BASE, BASE), Image.LANCZOS)
        cut = tile_bg.copy()
        cut.putalpha(mask)
        crop = cut.crop((round(BASE * 18 / 108),) * 2 + (round(BASE * 90 / 108),) * 2).resize((size, size), Image.LANCZOS)
        sheet.alpha_composite(crop, (x, 40))
        x += size + 30
    themed = Image.new("RGBA", (BASE, BASE), (60, 70, 68, 255))
    themed.alpha_composite(mono)
    sheet.alpha_composite(themed.crop((round(BASE * 18 / 108),) * 2 + (round(BASE * 90 / 108),) * 2).resize((420, 420), Image.LANCZOS), (1050, 40))
    out = ROOT / "build" / "icon_design"
    out.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(out / "final_sheet.png")
    print("Icon resources written. Review sheet:", out / "final_sheet.png")


if __name__ == "__main__":
    main()
