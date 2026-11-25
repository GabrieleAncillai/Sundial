#!/usr/bin/env python3
"""Generate Sundial launcher assets from the approved Penpot exports.

Sources live in branding/exports/. The approved 1024 px boards are used for
legacy icons and in-app previews. Adaptive background/foreground/monochrome
layers are exported from dedicated Penpot boards.

Run from the repository root:
    python3 tool/generate_icons.py
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
EXPORTS = ROOT / "branding/exports"
RES = ROOT / "android/app/src/main/res"
LINUX_ICONS = ROOT / "assets/icons/linux/hicolor"
FLUTTER_ICONS = ROOT / "assets/icons"

DENSITIES = {
    "mdpi": 1.0,
    "hdpi": 1.5,
    "xhdpi": 2.0,
    "xxhdpi": 3.0,
    "xxxhdpi": 4.0,
}
LEGACY_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ADAPTIVE_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
LINUX_SIZES = [16, 24, 32, 48, 64, 128, 256, 512]

# The foreground is scaled inside the 108 dp adaptive canvas so the sun stays
# inside the circular safe area. The background remains full-bleed.
ADAPTIVE_FOREGROUND_SCALE = 0.78


def load(name: str) -> Image.Image:
    return Image.open(EXPORTS / name).convert("RGBA")


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)


def resized(img: Image.Image, size: int) -> Image.Image:
    return img.resize((size, size), Image.Resampling.LANCZOS)


def centered_scale(img: Image.Image, scale: float) -> Image.Image:
    side = int(round(1024 * scale))
    offset = (1024 - side) // 2
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    canvas.alpha_composite(resized(img, side), (offset, offset))
    return canvas


def circular(img: Image.Image, size: int) -> Image.Image:
    square = resized(img, size)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    mask = mask.resize((size, size), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(square, (0, 0), mask)
    return out


def adaptive_xml(background: str, foreground: str, monochrome: bool) -> str:
    mono = '\n    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />' if monochrome else ""
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        f'    <background android:drawable="@drawable/{background}" />\n'
        f'    <foreground android:drawable="@drawable/{foreground}" />{mono}\n'
        '</adaptive-icon>\n'
    )


def main() -> None:
    full = {
        "classic": load("penpot-classic.png"),
        "aero": load("penpot-aero.png"),
    }
    backgrounds = {
        "classic": load("export-classic-background.png"),
        "aero": load("export-aero-background.png"),
    }
    foregrounds = {
        "classic": centered_scale(load("export-classic-foreground.png"), ADAPTIVE_FOREGROUND_SCALE),
        "aero": centered_scale(load("export-aero-foreground.png"), ADAPTIVE_FOREGROUND_SCALE),
    }
    monochrome = centered_scale(load("export-monochrome.png"), ADAPTIVE_FOREGROUND_SCALE)

    for variant in ("classic", "aero"):
        for density, legacy_size in LEGACY_SIZES.items():
            folder = RES / f"mipmap-{density}"
            save(resized(full[variant], legacy_size), folder / f"ic_launcher_{variant}.png")
            save(circular(full[variant], legacy_size), folder / f"ic_launcher_{variant}_round.png")
        for density, adaptive_size in ADAPTIVE_SIZES.items():
            folder = RES / f"drawable-{density}"
            save(resized(backgrounds[variant], adaptive_size), folder / f"ic_launcher_{variant}_background.png")
            save(resized(foregrounds[variant], adaptive_size), folder / f"ic_launcher_{variant}_foreground.png")
        for version in (26, 33):
            folder = RES / f"mipmap-anydpi-v{version}"
            folder.mkdir(parents=True, exist_ok=True)
            body = adaptive_xml(
                f"ic_launcher_{variant}_background",
                f"ic_launcher_{variant}_foreground",
                version >= 33,
            )
            (folder / f"ic_launcher_{variant}.xml").write_text(body, encoding="utf-8")
            (folder / f"ic_launcher_{variant}_round.xml").write_text(body, encoding="utf-8")

    for density, adaptive_size in ADAPTIVE_SIZES.items():
        save(resized(monochrome, adaptive_size), RES / f"drawable-{density}/ic_launcher_monochrome.png")

    for variant in ("classic", "aero"):
        save(resized(full[variant], 256), FLUTTER_ICONS / f"icon_{variant}.png")

    for size in LINUX_SIZES:
        for variant, icon_name in (
            ("classic", "io.github.sundial"),
            ("aero", "io.github.sundial.aero"),
        ):
            target = LINUX_ICONS / f"{size}x{size}/apps/{icon_name}.png"
            save(resized(full[variant], size), target)

    # Circular adaptive previews: the actual launcher mask is the useful check.
    for variant in ("classic", "aero"):
        composite = Image.alpha_composite(backgrounds[variant], foregrounds[variant])
        preview = circular(composite, 512)
        canvas = Image.new("RGB", (600, 600), (20, 30, 38))
        canvas.paste(preview, (44, 44), preview)
        canvas.save(EXPORTS / f"adaptive-{variant}-preview.png", "PNG", optimize=True)

    desktop = ROOT / "linux/packaging/io.github.sundial.desktop"
    desktop.parent.mkdir(parents=True, exist_ok=True)
    desktop.write_text(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Sundial\n"
        "GenericName=Planner\n"
        "Comment=A local-first planner for life, work and home.\n"
        "Exec=sundial\n"
        "Icon=io.github.sundial\n"
        "Terminal=false\n"
        "Categories=Office;Utility;\n"
        "StartupWMClass=io.github.sundial\n",
        encoding="utf-8",
    )

    print("Generated Android, Linux and in-app icon assets.")
    print("Adaptive foreground scale:", ADAPTIVE_FOREGROUND_SCALE)


if __name__ == "__main__":
    main()
