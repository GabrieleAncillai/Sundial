# Sundial brand assets

Status: **exploration only.** The launcher icon is still the stock Flutter
icon. The files here are concept renders used to choose a direction; nothing is
wired into `android/`, `linux/` or `pubspec.yaml` yet.

## Recommended pipeline

1. **SVG is the source of truth.** AI can read, diff and rewrite it; the shape
   stays editable and exports are deterministic.
2. **librsvg / ImageMagick** rasterise it. Both are already available on this
   machine (`magick -list format` reports `RSVG 2.62.4`), so no GUI is required.
3. **Inkscape** (optional, GPL-3.0) is for human node/curve polish. It is not
   required to build or export the icon.
4. **Blender** (optional, GPL) is a material and lighting pass, not the source
   of truth. Prefer a headless Python scene (`blender --background --python`)
   over keeping a binary `.blend` as the only record. Blender MCP is useful for
   live iteration, but it needs an open Blender GUI, an add-on and a localhost
   socket, so it is not a reproducible build step.
5. **flutter_launcher_icons** (MIT) generates Android mipmaps and the adaptive
   XML. Linux icons are installed through the packaging layer (hicolor PNG/SVG
   plus a `.desktop` file), not by flutter_launcher_icons.

Suggested asset layout when the direction is chosen:

```
branding/
  sundial-icon.svg          # master, 1024 x 1024
  foreground.svg            # adaptive safe-zone layer
  background.svg            # full-bleed layer
  monochrome.svg            # Android 13 themed icon
  blender/icon_scene.py     # optional material render
  exports/                  # generated PNGs, never hand-edited
```

## Concept renders

The current files are in `concepts/` and the PNG previews are in `exports/`:

- `a-sun-shadow.svg` - gold sun, dark S shadow, no gnomon. Reads cleanly at 32px.
- `b-sun-gnomon.svg` - the same mark with a white gnomon sliver. More literal.
- `c-gold-s.svg` - gold S on deep teal with a separate sun. Playful, less planner.
- `d-tilted-dial.svg` - a tilted dial plate. Object-like, weaker at small sizes.
- `e-in-app-orb.svg` - a polished version of the in-app orb. Brand-consistent but
  too detailed to survive 32px.

Render a preview:

```sh
mkdir -p branding/exports
for f in branding/concepts/*.svg; do
  name=$(basename "$f" .svg)
  magick -background none "RSVG:$f" -resize 512x512 "branding/exports/$name-512.png"
  for size in 96 48 32; do
    magick "branding/exports/$name-512.png" -resize "${size}x${size}" \
      "branding/exports/$name-$size.png"
  done
done
```

## Export constraints

- Android adaptive icon: 108 x 108 dp canvas, 66 x 66 dp safe zone. Keep the
  foreground inside that safe circle; do not bake the mask into the foreground.
- Test the icon at 48, 32 and 24 px, on light and dark home screens, and under
  circle, squircle and rounded-square masks.
- Provide a monochrome layer for Android 13 themed icons.
- Keep the mark to two or three shapes; hairlines and gloss highlights vanish
  below 48 px.
- Use the existing palette tokens: `#083247` / `#0B6E8A` (deep aqua),
  `#F2FAFF` (pearl), `#FFD166` / `#FFE08A` (sun). Do not introduce a new brand
  colour without documenting it.
- The icon is original work, bundled under the project's GPL-3.0-only terms.
  Do not copy Microsoft Aero or other platform assets.

## Next decision

Pick a direction (A or B is the current recommendation) and a pipeline:

- **Vector only** - fastest, crispest, all platform layers, no new installs.
- **Hybrid** - vector background and monochrome layer, Blender-rendered
  material for the hero/foreground. Best-looking, needs Blender.
