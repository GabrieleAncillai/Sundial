# Sundial brand assets

Status: **shipped.** The launcher icon is an original sundial mark, designed in
Penpot and exported through `tool/generate_icons.py`. Android ships **Classic**
and **Aero** launcher entries and lets the user switch between them in
Settings → Appearance → App icon. Linux ships the Classic icon in hicolor sizes.

## Source of truth

The design file is **Sundial Icons** in Penpot. It is not vendored here; the
checked-in PNG masters in `exports/` are the reproducible input for the asset
generator. The live file contains:

- `Icon / Classic Sundial` — cream, sage and brass; matte stone/metal.
- `Icon / Aero Sundial` — sky gradient, translucent glass dial, chrome gnomon,
  gold sun, bubbles and a glass rim catchlight.
- Full-bleed background boards and safe-zone foreground boards for both styles.
- A shared monochrome layer for Android 13 themed icons.
- Archived S-monogram studies, kept only as design history.

The mark is an actual sundial: a perspective dial plate with thickness,
engraved hour lines, chapter ring, cardinal diamonds, a beveled gnomon on a
plinth with rivets, a nodus bead, and a cast shadow that follows an hour line
from the style foot. The suns use smooth warm gradients without a white
specular blob.

## Why Penpot, not raw SVG or a raster generator

This is the decision record from the icon exploration:

- **Raw SVG authored by an LLM was rejected.** The result was stiff and hard to
  iterate. A design file with named layers and styles is the right abstraction.
- **Penpot + the official Penpot MCP was chosen.** It is FOSS (MPL-2.0), has a
  real design UI, and the AI can inspect and change layers through MCP. Penpot
  gradients are normalized (0..1), not pixels; drawing with pixel coordinates
  silently produces flat fills.
- **Blender was evaluated as a secondary tool.** It is the right choice for a
  glass/gold material hero render, but it is unnecessary for the final
  launcher; the Aero glass pass is built from Penpot layers.
- **AI raster generators are not used for the mark.** They are useful for
  moodboards, not for a crisp 24–48 px icon.
- **Figma is not used.** The MCP workflow is mature, but the tool is
  proprietary and cloud-based.

## Shipped artwork

- Masters: `exports/penpot-classic.png`, `exports/penpot-aero.png` (1024²).
- Adaptive layers: `exports/export-{classic,aero}-{background,foreground}.png`
  and `exports/export-monochrome.png`.
- Mask previews: `exports/adaptive-{classic,aero}-preview.png` and
  `exports/mono-preview.png`.
- In-app icons: `assets/icons/icon_classic.png`,
  `assets/icons/icon_aero.png` (256²). The launcher picker previews these and
  the shell logo renders the one matching the active visual style.

`tool/penpot_export.py` re-exports the Penpot boards. It reads the Penpot token
from the Zed settings file and must never print or commit that token.

## Android

`tool/generate_icons.py` writes:

- `mipmap-{mdpi..xxxhdpi}/ic_launcher_{classic,aero}[_round].png` for API < 26.
- `drawable-{mdpi..xxxhdpi}/ic_launcher_{classic,aero}_{background,foreground}.png`.
- `drawable-{mdpi..xxxhdpi}/ic_launcher_monochrome.png`.
- `mipmap-anydpi-v26` adaptive XML and `mipmap-anydpi-v33` XML with
  `<monochrome>`.
- `assets/icons/linux/hicolor/{16..512}/apps/io.github.sundial[.aero].png`
  and the `.desktop` entry.

The adaptive foreground is scaled to 0.78 of the 108 dp canvas so the sun stays
inside the circular safe zone. The launcher mask is never baked into the
foreground.

### In-app switching

Android cannot change a launcher icon directly at runtime. The supported
mechanism is **activity aliases**:

1. `MainActivity` keeps no MAIN/LAUNCHER filter.
2. `.ClassicIcon` and `.AeroIcon` are aliases that target `.MainActivity`, each
   with its own icon and round icon. Exactly one is enabled in the manifest.
3. A small Kotlin `MethodChannel` (`sundial/app_icon`) toggles the aliases with
   `COMPONENT_ENABLED_STATE_ENABLED/DISABLED` and `DONT_KILL_APP`.
4. The choice is stored as the device-local `appIconStyle` setting. It is not
   synced and is stripped from backups by `BackupService.deviceLocalSettingKeys`.
5. `main()` re-applies the stored choice on every launch, because an install,
   update or restore can reset alias state.

Some launchers cache the old icon. Settings shows a restart hint; the alias
switch itself is correct once the launcher refreshes.

## Linux

Both hicolor sets ship in `assets/icons/linux/hicolor`:
`io.github.sundial.png` (Classic) and `io.github.sundial.aero.png` (Aero).
`linux/CMakeLists.txt` installs the tree into the bundle's `share/icons`, and
the `.desktop` entry uses `Icon=io.github.sundial`.

The picker is available on Linux. The app writes the selected set to the user's
XDG data directory (`$XDG_DATA_HOME/icons/hicolor` or
`~/.local/share/icons/hicolor`) under the unchanged name
`io.github.sundial.png`, so the existing desktop entry resolves the new icon.
It re-applies the stored choice on launch and only writes files that differ.

The desktop shell may cache the old icon. Settings states that a logout/login
is required; that refresh is the accepted trade-off for a reliable switch
without editing the `.desktop` file or inventing a second app identity. The
bundle's `share/` tree still supplies the fallback icon and the desktop entry;
a system package installs it under `/usr`, and a local bundle user can copy it
under `~/.local/share`.

Wayland ignores per-window icon hints and GNOME/KDE read the launcher icon from
the desktop entry/icon theme, which is why this uses a user-local icon-theme
override rather than a window icon. A strict Flatpak sandbox may deny writes to
the host XDG data directory; the current tarball/package targets do not.

## Palette anchors

- `#083247` / `#0B6E8A` — deep aqua.
- `#F2FAFF` — pearl.
- `#FFD166` / `#FFE08A` — sun.
- `#F6F4EF` — Classic cream.
- `#4F6D5A` — Classic sage.

The icon is original work, bundled under the project's GPL-3.0-only terms. No
Microsoft Aero or other platform asset is copied.

## Verification

- `test/app_icon_test.dart` checks the parser, both platform paths, the
  settings row and every generated density/layer.
- Android real-device checks: switch Classic ↔ Aero, confirm the launcher entry
  is replaced (restart the launcher if cached), and confirm Android 13 themed
  icons use the monochrome layer.
- Linux real-device checks: switch Classic ↔ Aero, log out and back in, and
  confirm the dock/app-menu icon follows the choice. The app writes
  `$XDG_DATA_HOME/icons/hicolor` (default `~/.local/share/icons/hicolor`).
- Test 48, 32 and 24 px on light and dark home screens under circle, squircle
  and rounded-square masks.
