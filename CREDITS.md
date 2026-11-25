# Credits

## Inspiration and references

Sundial is an independent project inspired by two GPL-3.0-only projects by
[InlitX](https://github.com/InlitX):

- [GymMane](https://github.com/InlitX/GymMane): offline gym log for Android.
  A reference for small-app structure, theme, settings, backup and localisation.
- [Streak](https://github.com/InlitX/streak): offline habit tracker for Android,
  Windows and Linux. A reference for the calendar, reminders, notifications,
  motion, sync and feature-first architecture.

Sundial is not affiliated with or endorsed by InlitX. The upstream projects are
credited as design and architecture references. If any code is ever adapted from
them, their GPL-3.0-only notices and Section 7(b) attributions must be retained.

The Aero 2.0 style adapts the *language* of mid-2000s Frutiger Aero — sky,
glass, gloss, aqua, humanist type and optimistic futurism — using original code
and procedural art. No Microsoft, Apple or other proprietary Aero wallpaper,
icon, font or sound asset is bundled. The visual references are listed in
`docs/aero-2.md`.

The Home inventory catalog adapts the *concept* of GymMane's nutrition library
(`lib/services/food_library.dart` and the seeded TSV data): a searchable,
localized library with defaults and art that the user can extend. The household
item data, icons and screens are original to Sundial and remain GPL-3.0-only.
No GymMane code or data files are copied.

Sundial itself is GPL-3.0-only; see [LICENSE](LICENSE) and
[ADDITIONAL_TERMS.md](ADDITIONAL_TERMS.md).

## Assets

- **Nunito** (bundled in `assets/fonts/`, SIL Open Font License 1.1). The same
  face GymMane uses for its shell and type scale. The license text ships beside
  the font in `assets/fonts/Nunito-OFL.txt`.
- **Open Sans** (bundled in `assets/fonts/OpenSans/`, SIL Open Font License
  1.1). The Aero style face: a humanist Web 2.0 sans in the Frutiger/Segoe
  lineage. The license text ships as `assets/fonts/OpenSans/OFL.txt`.
- The Aero sundial mark, bokeh, sky, horizon and glass recipes are original
  Flutter vector/painter work. Material Icons are provided by Flutter through
  `uses-material-design`.
- **Interaction and alarm sounds** (`assets/sounds/` and the Android `res/raw`
  copies) are original procedural synthesis by the Sundial project. No
  third-party sound sample is bundled. Regenerate the interaction cues with
  `dart run tool/generate_sounds.dart`.
- **Launcher artwork** (`branding/exports/`, the Android mipmaps/drawables and
  `assets/icons/`) is original Sundial work designed in Penpot. No third-party
  icon or platform asset is copied. Regenerate it with
  `python3 tool/generate_icons.py`; the design record and source boards are
  described in `branding/README.md`.

Fonts, icons, illustrations, sounds and sample data are credited here when they
are added. Do not copy an asset without recording its source and license.
